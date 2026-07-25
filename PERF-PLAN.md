# Liquid Glass — performance-only refactor (2026-07-25)

HARD CONSTRAINT: **zero visual changes**. No layout, color, spacing, typography,
blur strength, or effect-appearance changes. Pixel output must be identical in
all four states (Liquid ON/OFF × light/dark). This is pure render-pipeline work.
The recent design overhaul was reverted on purpose (commit d3b6e77) — do not
reintroduce ANY part of it, and do not "improve" any visuals while you're in there.

Baseline before starting: `flutter analyze` clean; run `flutter test` first and
record the passing count — it must be identical when you finish.

Findings (all verified against current HEAD `d3b6e77`):

## P1 — Animated lens repaints INSIDE the BackdropFilter (codex)
`lib/src/ui/ft_glass.dart:124-186`: the non-lite path puts `GlassLensLayer`
(bottom of the `layers` Stack, :129-131) inside `BackdropFilter(compose(
saturation matrix + blur σ26))` (:180-186). `_LensPainter` subscribes to the
shared `LiquidFrame` via `super(repaint: frame)` (`ft_glass_fx.dart:55`), which
ticks ~15fps. No RepaintBoundary separates them, so every wallpaper drift step
re-executes the composed σ26 blur on nav/sheet/rail chrome, continuously.

Fix — restructure `_glass()` so the BackdropFilter's child never repaints:
keep EXACT paint order (backdrop-blur output → lens → tint/sheen → sweep →
child → touch glow → rim) but move the animated lens out of the filter's
subtree. Shape:
```
ClipRRect(
  Stack:
    Positioned.fill(BackdropFilter(compose(...), child: SizedBox.expand()))  // static child
    Positioned.fill(RepaintBoundary(GlassLensLayer(...)))                    // isolated 15fps repaint
    ... tint/sheen, sweep, child padding, touch glow — unchanged order ...
)
… rim CustomPaint stays foreground, shadow wrapper unchanged.
```
Verify order carefully: lens must render ABOVE the blurred backdrop and BELOW
tint/sheen, exactly as today. Confirm visually in /dev/liquid (Liquid ON/OFF,
light/dark).

## P2 — Every visible content card repaints at ~15fps (codex)
`ft_ui.dart:55-56`: `FtCard` uses `FtGlass(lite: true)` when Liquid is ON, and
each card's `_LensPainter` also subscribes to the frame notifier. A list of N
visible cards = N repaints per drift step, and without per-card RepaintBoundary
each repaint can dirty ancestors. Wrap the lite-glass card (or the
`GlassLensLayer` inside the lite path) in a `RepaintBoundary` so each card's
15fps repaint is isolated to its own layer. No visual change.

## P3 — Drift timer ignores whether anything consumes the frame (codex)
`ft_liquid_background.dart:63-70`: the `Timer.periodic` + `toImageSync` loop
(:95) runs whenever `_animate && _appVisible`, even on routes with no glass and
no visible wallpaper. Add consumer reference-counting on `LiquidFrame`
(`addConsumer`/`removeConsumer` called from painter attach/detach — CustomPainter
has `addListener`-time hooks via the painters' host widgets; simplest is
register in the `GlassLensLayer`/scene painter element lifecycle). Timer runs
only when consumers > 0 AND `_animate && _appVisible`. Keep all existing gates.

## P4 — Lens painter per-frame allocations (codex)
`ft_glass_fx.dart:63-127`: each tick re-runs `Path.combine(difference)` (:112)
and re-creates the `MaskFilter.blur` vignette paint (:120-126) and all Paint
objects. Cache the size/radius-dependent artifacts (paths, vignette paint) and
rebuild only when `size`/`borderRadius`/`dark` change. Output must be identical.

## P5 — FtShimmer ticks forever and ignores reduce-motion (opencode)
`ft_ui.dart` `_FtShimmerState`: `AnimationController(..)..repeat()` runs
unconditionally from initState, and build() has no
`MediaQuery.disableAnimationsOf` gate (pattern reference: `ft_motion.dart`
FtListReveal). Gate it: when animations are disabled, render `widget.child`
statically and don't tick the controller; manage start/stop in
didChangeDependencies. The shimmer's animated appearance when motion is ALLOWED
must be unchanged.

## Explicitly OUT OF SCOPE
- The classic nav's `fallbackBlurSigma: 18` (`ft_ui.dart:478`) — removing it
  would change the look. LEAVE IT.
- `GlassTouchGlow` setState-per-pointer-move — chrome-only, bounded. Leave.
- `GlassSweep` — already self-gating. Leave.
- Anything in lib/src/features/, theme.dart, or any visual constant.

## Verification (each agent)
1. `flutter analyze` — zero issues.
2. `flutter test` — same passing count as your recorded baseline.
3. codex additionally: open /dev/liquid lab, confirm identical rendering with
   Liquid ON and OFF, light and dark. Adding regression tests is welcome;
   changing existing test expectations is NOT (visuals must not change).
