# Refactor Progress

Tracking implementation of [REFACTOR_PLAN.md](REFACTOR_PLAN.md). Each phase logs what changed, when, why a deviation was made (if any), and how it was verified.

## Status overview

| Phase | Scope | Status |
|---|---|---|
| 1 | Design tokens & shared widgets | completed |
| 2 | Home / Beranda | completed |
| 3 | Core ledger screens | pending |
| 4 | Assets / Allocation, Goals, Health | pending |
| 5 | Profile, Members, Notifications, Settings, Access Control | pending |

---

## Phase 1 — Design tokens & shared widgets

**Started:** 2026-05-17
**Completed:** 2026-05-17

### Changes

- `lib/src/theme.dart` — switched sans font `interTextTheme()` → `geistTextTheme()` (verified Geist is in `google_fonts ^8.1.0`); added category palette accessors on `FtColors` (`catFood`, `catTransport`, `catBills`, `catShopping`, `catEntertainment`, `catHealth`, `catOther`) with both light/dark hex pairs from `claude-design/design/theme.jsx`.
- `lib/src/ui/ft_ui.dart` — no edit needed: `FtCard` already at radius 18, and `FtBottomNav` already uses `BackdropFilter` for the glass pill.
- New widgets under `lib/src/ui/`:
  - `ft_donut.dart` — rounded-cap donut chart with optional center label/value.
  - `ft_ring.dart` — circular progress ring (0..1 gauge) with optional child.
  - `ft_sparkline.dart` — tiny area+line chart for trend hints.
  - `ft_traffic_light.dart` — 3-state (good/caution/risk) indicator, horizontal or vertical, glow on active.
  - `ft_monthly_bars.dart` — labeled bar strip for multi-month comparisons / contribution history.
  - `ft_chip.dart` — soft or solid pill chip with optional leading icon.
  - `ft_glass_pill.dart` — generic backdrop-blur pill (for header buttons, custom chrome).
  - `ft_keypad.dart` — 12-key numeric keypad emitting `"0".."9"`, `"000"`, or `null` for backspace.
  - `ft_amount_display.dart` — large serif amount display with blinking cursor (uses `NumberFormat.decimalPattern('id_ID')` directly).
  - `ft_member_avatar.dart` — circular initials avatar + `FtMemberStack` for overlap effect via `Stack` + `Positioned` (negative-margin trick doesn't work in Flutter).
  - `ft_member_chip.dart` — inline name+dot chip for transaction rows.

### Deviations from plan

- `FtCard` radius bump was already at 18 in the existing `ft_ui.dart` — no edit needed; plan was based on an outdated assumption.
- `FtBottomNav` already had a backdrop-blur glass pill; the new `FtGlassPill` covers other places (header bell, top action pills, etc.).
- `FtMemberStack` ended up using `Stack`/`Positioned` instead of negative-padding `Row` (Flutter doesn't honor negative padding).

### Verification

- `flutter pub get` resolved cleanly (Geist via `google_fonts ^8.1.0`).
- `flutter analyze` → 24 issues, **none introduced by Phase 1** (all pre-existing `unnecessary_import` / `use_key_in_widget_constructors` / `unused_import` info-level lints from older code). Only Phase 1-introduced warning (`unused_import` in `ft_member_chip.dart`) was fixed before completing the phase.

---

## Phase 2 — Home / Beranda

**Started:** 2026-05-17
**Completed:** 2026-05-17

### Changes

- `lib/src/features/home/widgets/net_worth_section.dart` — rewrote as a single combined `AssetHeroCard` that pairs the big total, optional cycle-delta pill, optional sparkline, mini donut (cash/savings/investments segments via `FtDonut`), and a 3- to 4-column inline breakdown row. The old `AssetHero` and `AssetBreakdown` classes remain as thin shims (forwarding / no-op) so the alternate `HomeBBody` layout keeps compiling without edits.
- `lib/src/features/home/widgets/health_snapshot.dart` — added a `compact` mode for side-by-side use, swapped the small dot indicator for the new `FtTrafficLight` (horizontal in expanded mode, vertical in compact mode), and used `FtRing` for the score ring in the expanded variant.
- `lib/src/features/home/widgets/month_strip.dart` — added a `compact` mode (smaller eyebrow, tighter padding, single-line context, smaller progress bar) so it can share a row with the compact health card.
- `lib/src/features/home/home_screen.dart` — restructured the Layout A list to match `screens-home.jsx`:
  1. HomeHeader → 2. `AssetHeroCard` → 3. Banners/Due → 4. `MonthStrip(compact)` + `HealthSnapshot(compact)` side-by-side in an `IntrinsicHeight` row → 5. CategoryGrid → 6. CardsPreview → 7. GoalsPreview → 8. RecentList.

### Files left unchanged (already match the design)

- `home_header.dart` — already has avatar + name + member stack + bell + menu in a single row matching the design's header. Bell still triggers a snackbar; the real `/notifications` route is delivered in Phase 5.
- `category_grid.dart` — already a 2×2 grid with category icon + amount + progress bar + `% terpakai`/over-budget label per cell.
- `cards_preview.dart` — already has the eyebrow, min-pay chip, large total, segmented proportional-bar across cards, and nearest-due row.
- `goals_preview.dart` — already shows icon badge + progress bar + percentage + amounts per goal.
- `recent_list.dart` — already uses the existing `MemberChip` per row when a spender exists.
- `home_b_body.dart` (alternate Layout B) — does not reference `AssetHero`/`AssetBreakdown`, so it was unaffected by the merge.

### Deviations from plan

- `home_header.dart` was listed for edit but already matches the design closely; no changes were necessary.
- The existing `members/member_chip.dart` (avatar + first-name pill) is left intact and used by `recent_list.dart`. The new `lib/src/ui/ft_member_chip.dart` (color-dot + first-name) created in Phase 1 will be used by new screens in later phases — not retrofitted across this phase to keep the diff scoped.
- Bell wiring to `/notifications` deferred to Phase 5 along with the notifications screen itself.

### Verification

- `flutter analyze` → 23 issues, **none new from Phase 2** (3 pre-existing warnings + 20 pre-existing info-level lints; one Phase 1-introduced warning was already cleared). Compared to Phase 1's 24, the count dropped by one because the unused `ft_member_chip.dart` import is gone.
- No file exceeded the 400 LOC guardrail after edits.

---

## Phase 3 — Core ledger screens

_(not started)_

---

## Phase 4 — Assets / Allocation, Goals, Health

_(not started)_

---

## Phase 5 — Profile, Members, Notifications, Settings, Access Control

_(not started)_
