# Refactor Progress

Tracking implementation of [REFACTOR_PLAN.md](REFACTOR_PLAN.md). Each phase logs what changed, when, why a deviation was made (if any), and how it was verified.

## Status overview

| Phase | Scope | Status |
|---|---|---|
| 1 | Design tokens & shared widgets | completed |
| 2 | Home / Beranda | in_progress |
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

_(not started)_

---

## Phase 3 — Core ledger screens

_(not started)_

---

## Phase 4 — Assets / Allocation, Goals, Health

_(not started)_

---

## Phase 5 — Profile, Members, Notifications, Settings, Access Control

_(not started)_
