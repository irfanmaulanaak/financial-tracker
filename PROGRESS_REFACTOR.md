# Refactor Progress

Tracking implementation of [REFACTOR_PLAN.md](REFACTOR_PLAN.md). Each phase logs what changed, when, why a deviation was made (if any), and how it was verified.

## Status overview

| Phase | Scope | Status |
|---|---|---|
| 1 | Design tokens & shared widgets | completed |
| 2 | Home / Beranda | completed |
| 3 | Core ledger screens | completed |
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

**Started:** 2026-05-17
**Completed:** 2026-05-17

Resolves [ISSUES.md#7](ISSUES.md) (record screens > 400 LOC) and [ISSUES.md#8](ISSUES.md) (keypad/display widgets duplicated).

### Changes

**3a — shared record modules** (`lib/src/features/record_common/`):
- `amount_display.dart` — `RecordAmountDisplay` (eyebrow + big serif + colored blinking cursor). Accepts prefix, cursor color, active color.
- `keypad.dart` — `RecordKeypad` (12-key bottom keypad, hides when soft keyboard is up) + pure `applyRecordKey(amount, key)` helper.
- `meta_row.dart` — `RecordMetaRow` (date picker + recurring toggle; toggle hidden when `onToggleRecurring: null`).
- `category_chip_row.dart` — `CategoryChipRow` (wrapped category chips).
- `pay_type_toggle.dart` — `PayTypeToggle` ("Tunai / Debit" vs "Kartu Kredit").
- `payment_method_row.dart` — `PaymentMethodRow` (cash/debit/e-wallet method chips).
- `card_picker.dart` — `CardPicker` (horizontal credit-card tiles with usage bar + remaining).
- `installment_picker.dart` — `InstallmentPlans` (Lunas / 3× / 6× / 12×) + `InstallmentPreview` (monthly × N + total + interest from `cicilan.dart`).

Also new in `lib/src/ui/`:
- `ft_submit_dot.dart` — generic `FtSubmitDot` check button with `activeColor` for ink (expense) / moss (income) / plum (cards) flows.

**3b — restyles**:
- `spend_screen.dart` — already aligned (hero + donut + month picker + category breakdown); no edits.
- `categories/category_detail_screen.dart` — already aligned (icon hero + progress + analysis grid + 14-day bars + verdict box); no edits.
- `expenses/expense_log_screen.dart` — added `_TodayCard` at top (eyebrow + serif "Hari ini" total + `FtAddButton` quick-add); removed unused `go_router` import.

**3c — cards split + pay sheet**:
- New `lib/src/features/cards/pay_card_sheet.dart` — `PayCardSheet.show(...)` modal with min/full/custom radio options + `FtKeypad(compact: true)` for the custom path; commits via `payMinimum` / `payFull` / `applyUsageDelta(delta: -amount)`.
- New `lib/src/features/cards/widgets/card_tile.dart` — `CardTile` (gradient card + owner/limit/due grid + installments + single "Bayar tagihan" button that opens the sheet).
- New `lib/src/features/cards/widgets/installment_list.dart` — `CardInstallmentsInline` + public `cardInstallmentsProvider` shared across cards-screen / card-detail / home-summary so they share one Firestore subscription per (hid, cardId). Plus `CardCicilanTotal` helper.
- `cards_screen.dart` — removed local `_CardTile`/`_CardActions`/`_CardInstallmentsInline`/`_parseColor`; switched to public `cardInstallmentsProvider`; replaced the two confirm dialogs with the new sheet; `_LabeledStat` / `_CicilanTotalStat` / `_SaranTip` left in place since they're screen-local.
- `card_detail_screen.dart` — dropped the duplicate local `_installmentsProvider` in favor of the public one.

**3d — record screens refactor**:
- `expenses/record_expense_screen.dart` — switched local `_SubmitDot` → `FtSubmitDot`, `_AmountDisplay`+`_BlinkCursor` → `RecordAmountDisplay`, `_Keypad` → `RecordKeypad`, `_MetaRow` → `RecordMetaRow`, `_CategoryChips`/`_PayTypeToggle`/`_MethodChips`/`_CardPicker`/`_CicilanPlans`/`_CicilanPreview` → the matching `record_common` widgets; deleted all extracted local classes and now-unused imports (`cicilan`, `formatters`, `ft_motion`). 1,145 LOC → 312 LOC (-833).
- `incomes/record_income_screen.dart` — same swap pattern for the four shared widgets; deleted local copies. 654 LOC → 382 LOC (-272).

### Deviations from plan

- The local `_AmountDisplay`/`_BlinkCursor`/`_Keypad`/`_MetaRow` in record screens were record-screen-tuned (Newsreader 22px keypad, eyebrow above amount, custom cursor pulse). The plan suggested re-exporting the Phase 1 `FtAmountDisplay`/`FtKeypad`; instead I shipped record-flow-specific siblings (`RecordAmountDisplay`/`RecordKeypad`) and left the generic primitives untouched for non-record flows (pay-card sheet uses `FtKeypad(compact: true)`, add-goal/edit-asset will use them too in Phase 4).
- `cards_screen.dart` ended up with one combined "Bayar tagihan" button per card that opens `PayCardSheet`, instead of two separate min/full buttons. The sheet covers all three options (min/full/custom) so the inline two-button layout was redundant.
- Promoted the per-card installments stream provider to public (`cardInstallmentsProvider`) and pulled `card_detail_screen.dart` onto it to avoid duplicating the Firestore subscription.
- `spend_screen.dart` and `category_detail_screen.dart` had no functional gaps versus the design; left them alone instead of cosmetic re-shuffling.

### Verification

- `flutter analyze` → **20 issues, 0 errors, 0 new warnings from Phase 3** (3 pre-existing warnings + 17 pre-existing info-level lints).
- File LOC after Phase 3:
  - `record_expense_screen.dart`: 312 ✓ (was 1,145)
  - `record_income_screen.dart`: 382 ✓ (was 654)
  - `cards_screen.dart`: 356 ✓ (was 677)
  - `card_detail_screen.dart`: 361 ✓
  - `pay_card_sheet.dart`: 298 ✓
  - `widgets/card_tile.dart`: 166 ✓
  - `widgets/installment_list.dart`: 145 ✓
  - Each new `record_common/*.dart` module under 220 LOC.
- Files still above 400 LOC that Phase 3 did NOT touch (queued for later phases): `accounts_screen.dart` 635 (Phase 4), `settings_screen.dart` 640 (Phase 5), `insights_screen.dart` 792 (folds into Phase 4 health screen), `ft_ui.dart` 769 (cross-cutting chrome — kept as-is intentionally), `category_detail_screen.dart` 450 (close to limit; acceptable for an analytics screen), `spend_screen.dart` 422, `expense_log_screen.dart` 416, `investments_screen.dart` 414, `home/widgets/home_b_body.dart` 411.

---

## Phase 4 — Assets / Allocation, Goals, Health

_(not started)_

---

## Phase 5 — Profile, Members, Notifications, Settings, Access Control

_(not started)_
