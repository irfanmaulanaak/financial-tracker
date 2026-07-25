# De-slop refinement spec — 2026-07-25

Owner-approved 4-point plan. This REFINES the current warm aesthetic — it is NOT
a redesign. Layout, spacing, component shapes, and the warm character all stay.
Anything not listed here must not change. Baseline: flutter analyze clean,
flutter test 313 passing (may shift slightly as the concurrent copy-pass agent
updates string expectations — coordinate on final count).

## D1. Numerals: serif display → sans (biggest tell)
`lib/src/theme.dart:109-128`: display/headline/titleLarge use Newsreader serif.
Serif display numerals ("Rp186.1 jt") are the loudest AI-default tell on screen.
- Switch display*/headline*/titleLarge to Geist (the existing sans), same sizes,
  weight w500→w600 for display sizes (sans needs slightly more weight at large
  sizes to hold the same presence), keep the tight letterSpacing.
- Add `FontFeature.tabularFigures()` to every style that renders money or
  changing numbers (display*, headline*, and any explicit money styles in
  widgets). Currently there are ZERO tabular-figure declarations in theme.dart.
- Newsreader may remain ONLY if used somewhere as small italic accent text —
  if nothing else uses it after this change, remove the import.

## D2. One accent color
Multiple hues (clay/terracotta, sage, ochre, sky, plum) currently act as page
accents across 39 feature files. Keep ALL of them defined in FtColors (charts/
categories still need them) but demote: the ONLY colors allowed on interactive
elements (buttons, selection, links, active nav, FAB, toggles) are:
- `clay` (warm orange/terracotta) = the single action accent, and
- semantic green/red/ochre strictly for financial state (income/expense/warning).
Sweep lib/src/features for sage/sky/plum used on buttons, chips, selected
states, section headers, or icons-that-are-actions and replace with clay or
neutral ink. Chart series, category dots, and the donut keep their palette.

## D3. Canvas: warm near-black, flatter
Dark `bg` is `#14130f` with brownish gradient washes visible on device.
- Deepen: bg → #0F0E0B, bgAlt → #14130F, surface → #191813, surfaceAlt → #1F1D17
  (same warm hue family, one step darker/quieter; data pops more).
- Light mode values unchanged.
- If FtLiquidBackground's wallpaper blob colors reference the old bg values,
  re-tune ONLY the base canvas color of the wallpaper to the new bg so the glass
  scene doesn't look detached. Blob accent colors unchanged.

## D4. Progress bars: one hue, varying intensity
Category/budget progress bars currently use each category's own color (red/
pink/orange/yellow rainbow on the home grid — device screenshot confirms).
- FtProgressBar consumers for BUDGET/progress semantics: single hue = clay,
  with intensity/alpha stepped by state (under budget: clay at 0.55 alpha;
  near limit: clay full; over budget: the existing danger red — semantic
  exception stays).
- Goal progress bars: same treatment (clay family).
- The donut chart and category DOTS keep per-category colors (legend present).

## Verification
1. flutter analyze — zero issues.
2. flutter test — all passing; update test expectations that assert specific
   colors/fonts where the spec changes them (list each in your report).
3. Report which files changed per point so the orchestrator can re-screenshot
   the device (home, spend, aset, tujuan, utang) and diff against the "before"
   set already captured.
