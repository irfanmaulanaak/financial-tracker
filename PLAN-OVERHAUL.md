# FinSist Overhaul Plan — 2026-07-24

Handoff brief for implementation agents (codex = heavy tasks, opencode = light tasks).
Research, review, and task split by Claude. `DESIGN.md` remains the visual source of
truth; this file only lists the delta work. Do NOT revert the uncommitted working-tree
changes — they are the in-progress FinSist re-skin and are intentional.

Baseline (verified today): `flutter analyze` clean, `flutter test` 313/313 passing.
Every task below must keep both green.

---

## Part A — Liquid Glass performance (codex)

Audit findings, in priority order. All code paths cited were verified today.

### A1. BackdropFilter re-executes at ~12fps because the animated lens is INSIDE it
- `lib/src/ui/ft_glass.dart:100-175`: the liquid path stacks `GlassLensLayer`
  (CustomPaint) → tint/sheen DecoratedBox → child, then wraps the whole stack in
  `ClipRRect` → `BackdropFilter(ImageFilter.compose(blur 18σ + saturation matrix))`.
- `lib/src/ui/ft_glass_fx.dart:53`: `_LensPainter` uses `super(repaint: frame)` where
  `frame` is the global `LiquidFrame` ChangeNotifier ticking ~12fps
  (`ft_liquid_background.dart:29,61`).
- There is no RepaintBoundary between the lens and the BackdropFilter, so every drift
  step forces the composed 18σ blur to re-run — on every screen, all the time, while
  Liquid is ON. This is the #1 cost.

Fix: restructure `FtGlass` so the BackdropFilter's child subtree is static.
Recommended shape:
```
ClipRRect(
  BackdropFilter(blur+sat)          // child below must never repaint per-frame
    → static tint/sheen DecoratedBox + child content
) 
… with GlassLensLayer painted ABOVE the filter as a sibling in an outer Stack,
wrapped in its own RepaintBoundary (it already draws with per-image alpha, so it
composites fine on top), rim painter stays foreground.
```
Verify visually in the dev lab (`/dev/liquid`, `lib/src/features/dev/liquid_preview_screen.dart`)
that the lens refraction still reads correctly over the drifting wallpaper.
Also wrap the whole glass surface in a RepaintBoundary so nav repaints don't leak.

### A2. Classic (Liquid OFF) bottom nav runs a permanent 16σ BackdropFilter
- `lib/src/ui/ft_ui.dart:462`: `FtBottomNav` passes `fallbackBlurSigma: 16`, so the
  DEFAULT theme pays a live blur on every screen (`ft_glass.dart:88-97`).
- Fix: drop the fallback blur for the bottom nav (solid `fallbackAlpha` surface like
  the side nav uses, `ft_side_nav.dart:68`), or reduce to a one-time cheap effect.
  A solid ~0.92 alpha surface + hairline is consistent with DESIGN.md.

### A3. Drift timer runs regardless of visibility
- `ft_liquid_background.dart:54-66`: `_syncTimer` gates only on `_animate && _appVisible`
  (lifecycle). It keeps rendering `toImageSync` (~12fps, `:81`) even when no glass
  chrome is on screen (`showNav:false` routes), or when an opaque route covers it.
- Fix: reference-count consumers. `LiquidScene`/`LiquidFrame` should only tick while at
  least one lens/background painter is subscribed AND visible. Simplest: have
  `GlassLensLayer`/`_ScenePainter` register/unregister on attach/detach and stop the
  timer at zero registrations. Keep existing lifecycle + reduce-motion gates.

### A4. Two stacked glass surfaces should share a backdrop
- When an action sheet opens over the nav (`ft_action_sheet.dart:38,78`) there are two
  simultaneous BackdropFilters. On Impeller, use `BackdropGroup` +
  `BackdropFilter.grouped` (Flutter ≥3.27) so the engine performs one shared blur —
  BUT only if the two surfaces don't overlap on screen (nav is hidden behind sheet
  scrim; verify). If they overlap, skip this and rely on A1/A2.

### A5. Housekeeping inside the glass stack
- `_LensPainter.paint` (`ft_glass_fx.dart:61-126`) allocates paths/paints per frame and
  does `Path.combine(difference)` + `MaskFilter.blur` stroke each tick. Cache what is
  size/radius-dependent (recompute only when size or radius changes).
- Dead code: `GlassLensLayer.lite` (`ft_glass_fx.dart:18-27`) is never used with
  `lite:true`. Either wire it or delete the flag.
- Measure before/after with `flutter run --profile` + DevTools raster stats if
  possible; otherwise reason via timeline of repaint regions
  (debugRepaintRainbowEnabled in the dev lab is acceptable evidence).

---

## Part B — Design overhaul (codex, after Part A)

The direction is ALREADY chosen and documented in DESIGN.md (calm bank-statement,
neutral canvas, one action blue, semantic color only, hairlines, glass only on chrome).
The working tree re-skin implements the tokens. What still reads as "AI generated" is
structural monotony: home_overview.dart:101, category_grid.dart:35,
goals_preview.dart:28, recent_list.dart:35 are all the IDENTICAL
`Container(surface + Border.all(line) + radius 12)` ledger box, each with the same
`FtSectionHeader` above and the same [icon | label/value | trailing] row inside.

Research-backed fixes (Copilot Money / Ramp / Apple HIG patterns — hierarchy through
scale and whitespace, not boxes):

### B1. Give home ONE hero and demote everything else
- `_DailyLimitPanel` (home_overview.dart) becomes the single unboxed hero: large
  tabular numeral (~34-40px, w600, tight tracking) directly on the canvas, label above,
  one-line annotation below, no container border. The 4px accent bar goes away —
  express state through the numeral color or a small dot + word, not a strip
  (colored left/side strips are a known AI tell).
- The "Ringkasan" ledger keeps its bordered-group treatment (it IS a ledger — that's
  the correct semantic) but is the ONLY bordered group in the top half.

### B2. Vary section treatments — whitespace-first grouping
- CategoryGrid + GoalsPreview + RecentList: at most ONE of these keeps the bordered
  box. The others separate rows with whitespace + inset hairlines directly on canvas
  (no outer border), per DESIGN.md "Group related rows with spacing and dividers
  before adding another card". Suggested: RecentList keeps the box (transactional
  ledger); categories + goals go borderless with a slightly stronger section header.
- Keep every existing behavior/test contract (taps, semantics, amounts). Update the
  widget tests' expectations only where a border/container finder changes.

### B3. Kill remaining generic tells
- `lib/src/features/cards/widgets/card_tile.dart:45-64`: remove the accent→plum
  LinearGradient (hardcoded second stop) — use a solid accent-tinted surface or a
  very subtle same-hue tonal shift; drop `.toUpperCase()` + letterSpacing 1.1.
- FAB double drop-shadow (`ft_ui.dart:375-386`): single soft shadow.
- Traffic-light glow (`ft_traffic_light.dart`): keep, but halve the glow radius —
  or replace glow with a filled-vs-outline distinction.

### B4. Typography hierarchy pass
- Keep Inter (DESIGN.md decision) but push numeric hierarchy: money values on home
  hero and section rows should differ by SIZE (scale ~1.25 steps), not by adding
  weights. Ensure tabular figures on every changing number. No new fonts.

---

## Part C — Light cleanup (opencode)

### C1. Purge stale design-archaeology comments (~30 hits)
Comments describing the dead cream/serif/claude-design aesthetic. Find with:
`grep -rn "cream\|serif\|claude-design\|warm surface\|terracotta" lib/src --include="*.dart"`
- `ft_action_sheet.dart:12-15` (doc comment is also DUPLICATED twice — fix that),
  `ft_ui.dart:66,609`, `ft_input.dart:6`, `ft_refresh.dart:6`, plus feature files.
- Rewrite each to describe the CURRENT FinSist behavior in the same language style
  as neighboring comments (repo uses Indonesian for many doc comments — match
  whichever the file already uses). Do not touch code.

### C2. FtShimmer must respect reduce motion
- `ft_ui.dart:851-861`: `AnimationController..repeat()` ignores
  `MediaQuery.disableAnimations`. Gate it like `FtListReveal` does
  (`ft_motion.dart:279` pattern): static placeholder when animations are disabled.

### C3. Do NOT delete home_hero_carousel.dart / safe_to_spend_slide.dart
They are unreferenced in lib/ but their tests were just intentionally updated —
owner may still be iterating. Leave them alone this pass.

---

## Verification (every agent, before finishing)
1. `flutter analyze` — zero issues.
2. `flutter test` — all pass (baseline 313).
3. For Part A: open `/dev/liquid` lab and confirm glass renders correctly with
   Liquid ON and OFF, light and dark.
