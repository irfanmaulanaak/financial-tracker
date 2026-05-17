# Refactor Progress

Tracking implementation of [REFACTOR_PLAN.md](REFACTOR_PLAN.md). Each phase logs what changed, when, why a deviation was made (if any), and how it was verified.

## Status overview

| Phase | Scope | Status |
|---|---|---|
| 1 | Design tokens & shared widgets | completed |
| 2 | Home / Beranda | completed |
| 3 | Core ledger screens | completed |
| 4 | Assets / Allocation, Goals, Health | completed |
| 5 | Profile, Members, Notifications, Settings, Access Control | completed |

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

**Started:** 2026-05-17
**Completed:** 2026-05-17

### Changes

**4a — Allocation engine + Aset Alokasi tab**:
- New `lib/src/core/allocation_recommendation.dart` — pure `computeAllocation({totalLiquid, totalSavings, investments, profile})` that returns `AllocationRecommendation` (current segments, target segments, rebalancing moves, summary text, in-balance flag). Maps investment kinds to four buckets: `liquid` (cash + savings), `growth` (stocks/etf/funds/crypto-volatile), `stable` (gold/bonds/deposits), `alternatif` (crypto + others). Default `moderate` profile mirrors `data.jsx`: 30/45/20/5.
- `lib/src/features/accounts/widgets/alokasi_tab.dart` — rewrote: context card → current/target toggle (`_Toggle`) → `FtDonut` allocation card with legend rows (`_LegendRow`) → rebalancing list. Replaces the old `PieChart` view.
- New `lib/src/features/accounts/widgets/rebalance_moves.dart` — extracted moves list (`RebalanceMoves`, `_MoveRow`, `_Pill`) to keep `alokasi_tab.dart` under 400 LOC.
- New `lib/src/features/accounts/widgets/account_tab.dart` — generic list body shared between cash + savings tabs.
- New `cash_tab.dart` / `savings_tab.dart` — thin wrappers picking the right `AccountKind`.
- New `lib/src/features/accounts/widgets/assets_hero.dart` — extracted hero (Total Aset + composition bar + 3-col breakdown) from `accounts_screen.dart`.
- `accounts_screen.dart` — slimmed from 635 LOC → 199 LOC, delegating to the four widget files above. Tab bodies now just instantiate `CashTab`/`SavingsTab`/`InvestasiList`/`AlokasiTab`.

**4b — Goal model + add-goal flow**:
- `lib/src/features/goals/goal.dart` — extended model with `autoDebit`, `autoDebitDay`, `sourceAccountId`, `presetId`, `lastAutoDebitMonth`. `toMap` / `fromSnapshot` updated.
- `lib/src/features/goals/goal_repository.dart` — `add` / `updateGoal` accept the new fields; new `markAutoDebitDone(...)` writes `lastAutoDebitMonth` for the runner's idempotency.
- New `lib/src/features/goals/widgets/goal_preset_grid.dart` — 3×2 preset cards (Dana Darurat / Liburan / Rumah / Gadget / Pernikahan / Lainnya) seeding default amount + tone color.
- New `lib/src/features/goals/widgets/goal_amount_fields.dart` — twin Target / Saat ini fields with the active field highlighted (input drives the keypad).
- New `lib/src/features/goals/widgets/goal_form_parts.dart` — `GoalPreviewHero`, `GoalToneRow`, `GoalMonthsRow`, `GoalProjectionCard` + helper formatters.
- New `lib/src/features/goals/widgets/goal_source_picker.dart` — `GoalSourceAccounts` (cash account picker) + `GoalAutoDebitToggle`. Split out of `goal_form_parts.dart` to stay under the LOC limit.
- New `lib/src/features/goals/add_goal_screen.dart` — full new flow at `/goals/new`: preset picker → preview hero → name input → tone row → target/current amounts → duration months → projection card → source account → auto-debit toggle → keypad → submit dot. Replaces the old `goal_edit_sheet.dart` (trashed).
- `goals_screen.dart` — restyled list: tone-colored `goal_card.dart` rows with progress bar + warning chip when `daysOff > 14`. Add-goal CTA + dashed "Tambah goal" tile both push `/goals/new`.
- `goal_card.dart` — restyled to colored icon badge + compact money formatter + warning indicator + soft progress bar.
- `goal_detail_screen.dart` — replaced `CircularProgressIndicator` with `FtRing` for the hero ring; kept stats, contribution history, and edit/delete actions.

**4c — Auto-debit runner**:
- New `lib/src/features/goals/auto_debit_runner.dart` — client-side runner mirroring `recurring_runner.dart`. Pure `monthsToMaterialise({lastSeen, now})` returns the YYYY-MM list to materialise (capped to 6 to handle stale users). `runAutoDebitOnce` reads goals with `autoDebit && !done && cycleEnd <= now`, debits the linked source account, increments `current`, and stamps `lastAutoDebitMonth` for idempotency. Runs **once per app session** via `autoDebitRunnerProvider`.
- `home_screen.dart` — mounts `autoDebitRunnerProvider` alongside `recurringRunnerProvider` once a household is loaded.

**4d — Health screen**:
- New `lib/src/features/health/health_screen.dart` — `/health` route. Pulls live cycle expenses, previous-cycles average, household income/budget, cards, investments → builds `HealthScoreInputs` → renders score + factors + findings + recommendations. Layout mirrors `screens-rest.jsx > HealthScreen`.
- New `lib/src/features/health/widgets/health_hero.dart` — vertical `FtTrafficLight` + score + verdict copy.
- New `lib/src/features/health/widgets/health_findings.dart` — "Temuan Pengeluaran" top-N category deltas vs the previous-cycles average; tap drills into `/categories/:id`.
- New `lib/src/features/health/widgets/health_recommendations.dart` — derived recommendations (debt-priority, build-emergency-fund, start-investing, review-budget) routing to relevant screens.
- `health_screen.dart` itself: factor breakdown rows use `FtRing` per metric.

**4e — Routing + navigation**:
- `lib/src/router.dart` — added `/health` (HealthScreen) and `/goals/new` (AddGoalScreen). Both `_fadeRoute`-wrapped. `/goals/new` registered before `/goals/:goalId` so the path-segment matcher resolves correctly.
- `home_screen.dart` — both the side-by-side `HealthSnapshot` and the layout B `onInsights` callback now push `/health` instead of `/insights`. The `insights` menu entry still routes to `/insights` (legacy analytics screen) — slated for removal in Phase 5.

### Deviations from plan

- Allocation profile is hard-coded to `moderate` (30/45/20/5). The plan left "static allocation shape" open; we expose `AllocationProfile` enum + an unused profile param so a future risk-tier picker can flip to conservative/aggressive without touching callers.
- Auto-debit runner is **client-side only** (idempotent via `lastAutoDebitMonth` per goal). A backend Cloud Function would be safer for multi-device households but is out of scope per the household size note in `AGENTS.md`.
- `goal_edit_sheet.dart` was deleted (`trash`) instead of left as a shim — `AddGoalScreen` covers create + edit by passing an existing goal id.
- `insights_screen.dart` is **not deleted**; only the home health card was redirected to `/health`. The `insights` menu item and the `/insights` route stay alive until Phase 5 cleanup.
- Two new widget files (`assets_hero.dart` + `account_tab.dart`) appeared in the accounts split that the plan didn't explicitly call out — they were necessary to land `accounts_screen.dart` under the LOC budget.

### Verification

- `flutter analyze` → **13 issues**, all pre-existing info-level lints in code outside Phase 4 scope (unnecessary `ft_motion.dart` imports in record/insights/spend/settings; const-constructor hints in `ft_ui.dart`; one unused `_runIncomes` from earlier work). **0 new warnings/errors from Phase 4.** All Phase 4-touched files cleared their own redundant imports as part of this phase.
- File LOC after Phase 4 (all under 400 ✓):
  - `accounts_screen.dart`: 199 (was 635)
  - `widgets/alokasi_tab.dart`: 325; `widgets/rebalance_moves.dart`: 161; `widgets/account_tab.dart`: 271; `widgets/assets_hero.dart`: 183; `widgets/cash_tab.dart`: 31; `widgets/savings_tab.dart`: 29
  - `add_goal_screen.dart`: 268; `widgets/goal_form_parts.dart`: 307; `widgets/goal_source_picker.dart`: 219; `widgets/goal_amount_fields.dart`: 139; `widgets/goal_preset_grid.dart`: 159; `widgets/goal_card.dart`: 207
  - `goals_screen.dart`: 202; `goal_detail_screen.dart`: 295; `auto_debit_runner.dart`: 176
  - `health_screen.dart`: 215; `widgets/health_hero.dart`: 121; `widgets/health_findings.dart`: 182; `widgets/health_recommendations.dart`: 161
  - `core/allocation_recommendation.dart`: 232
  - One borderline file: `widgets/investasi_list.dart` 404 — pre-existing, not Phase 4 scope, will be split in Phase 5 cleanup.
- Manual route check: `/health` and `/goals/new` both resolve via the GoRouter table; home health card opens `HealthScreen`.

---

## Phase 5 — Profile, Members, Notifications, Settings, Access Control

**Started:** 2026-05-17
**Completed:** 2026-05-17

### Changes

**5a — Access-tier model + rules**:
- `lib/src/features/household/household.dart` — added `AccessLevel` enum (`full` / `limited` / `view`) with id↔string converters + ID-locale labels (`accessLevelLabel`, `accessLevelDetail`). Extended `MemberRole` with `orangTua` and `lainnya`. `Member` gained an `accessLevel` field (defaults `full`). `Household` exposes `Household.memberAccessMap(members)` so the repo can keep a `{uid: levelString}` mirror on the household doc for cheap rules evaluation. `toMap()` now writes `memberAccess` and bumps `schemaVersion` to 2.
- `lib/src/features/household/household_repository.dart` — `createInvite(...)` now accepts `MemberRole` + `AccessLevel`, persists them on the invite doc; `joinWithInvite(...)` reads them back so joiners land with the level the inviter chose. `create(...)` and `joinWithInvite(...)` write the `memberAccess` map on the household. **Member moderation methods extracted** into `lib/src/features/household/member_management.dart` (Dart `part` file) to keep `household_repository.dart` under the LOC budget: `removeMember(...)` (creator-only), `updateMemberAccess(...)` (creator-only), and `updateMyProfile(...)` (caller's own row).
- `firestore.rules` — rewrote household + subcollection rules. `households/{hid}` now allows `get` for any signed-in user (so accept-invite can read the doc) but blocks `list` for non-members. `update` requires `memberAccess[uid] == 'full'`. Subcollections (`expenses`, `incomes`, `cards`, `goals`, `investments`) are gated by helper functions `isMember()`, `level()`, `canTxn()`, `canFull()`: `view` is read-only across the board, `limited` can write `expenses` + `incomes` only, `full` can write everything. Card `installments` inherit the parent card's gating. `invites/{code}` now stores `role` + `accessLevel` and is readable by any signed-in user (so we can preview the invite before joining).
- `lib/src/features/household/household_providers.dart` — new `myAccessLevelProvider` (derives level from current household + uid; defaults to `full` for solo creators / `view` if uid not in members), `canRecordTxnProvider` (`full` or `limited`), and `canWriteAllProvider` (`full` only). Plus `orphanedMembershipCleanupProvider`: when the household stream finishes loading and the current uid isn't in `members[]`, the user's `users/{uid}.householdId` is cleared client-side so the router yanks them back to onboarding (rules block the creator from doing this on their behalf, so the orphan must heal itself).

**5b — Profile + member detail screens**:
- New `lib/src/features/profile/edit_profile_screen.dart` (188 LOC) — `/profile/edit` route. Edits display name + accent color (10-swatch palette) on the household member row via `updateMyProfile(...)`. Read-only email card (Firebase Auth source of truth). Account-deletion CTA hits `auth_repository.deleteCurrentUser()` after a confirm dialog.
- New `lib/src/features/profile/widgets/edit_profile_parts.dart` (366 LOC) — extracted `SaveButton`, `AvatarPreview`, `AccentRow`, `InfoCard`, `SecurityCard`, plus the `initialsFor` helper, to keep the screen file slim.
- `lib/src/features/auth/auth_repository.dart` — added `deleteCurrentUser()` (Firebase Auth `currentUser?.delete()`); rules-driven Firestore data lifecycle is unchanged (cleanup happens via `leave(...)` before deletion in the UI flow).
- New `lib/src/features/members/member_detail_screen.dart` (196 LOC) — `/members/:memberId` route. Hero (avatar + name + role + access pill), contact card (email if available — pulled from auth metadata when the member is the viewer themselves; otherwise hidden by rules), monthly activity card (`expensesProvider` filter by spender), creator-only "Ubah akses" + "Keluarkan dari household" actions. Uses `AccessPickerSheet.show(...)` for the level picker.
- New `lib/src/features/members/widgets/access_picker_sheet.dart` (153 LOC) — three-radio sheet (`full` / `limited` / `view`) with the long-form description from `accessLevelDetail`.
- New `lib/src/features/members/widgets/member_detail_parts.dart` (399 LOC) — `MemberHero`, `MemberContactCard`, `MemberAccessCard`, `MemberActivityCard` (member-specific UI extracted from the screen).

**5c — Settings split + invite flow**:
- `lib/src/features/settings/settings_screen.dart` — slimmed from **640 → 307 LOC** by extracting:
  - `widgets/members_section.dart` (224 LOC) — household members list (avatar + name + role chip + access pill); tap-through to `/members/:memberId`; "Undang anggota" CTA gated by `canWriteAllProvider`.
  - `widgets/household_section.dart` (194 LOC) — household name + payday + monthly budget editors. All write paths gated by `canWriteAllProvider`; for `view` / `limited` users the rows are read-only.
  - `widgets/settings_row.dart` (130 LOC) — reusable `SettingsRow`, `SettingsToggleRow`, `SettingsChoiceChip` (label + value + chevron primitive shared across the screen).
- `lib/src/features/members/invite_sheet.dart` (281 LOC) — rewrote: role picker (5 chips: Suami / Istri / Anak / Orang Tua / Lainnya) + access-level radio (`Full akses` / `Catat transaksi` / `Lihat saja`) + generated `FT-XXXX` code with copy + WhatsApp share. `createInvite(...)` is called with both role + level so the joiner inherits the inviter's choice.
- New `lib/src/features/members/widgets/invite_sheet_parts.dart` (246 LOC) — `InviteHeading`, `RoleChip`, `AccessOption`, `GhostButton`, `SheetGrabber`.

**5d — Notifications**:
- New `lib/src/features/notifications/notification_providers.dart` (164 LOC) — `AppNotification` (icon + tone + title + subtitle + timestamp + `onTap`) and a derived `notificationsProvider` that aggregates: budget-warning chips when category usage >80%, card statements with `daysUntilDue ≤ 7`, goal milestone hits (50% / 75% / 100%), recent member spend > 100k IDR. Sorted desc by timestamp.
- New `lib/src/features/notifications/notifications_screen.dart` (211 LOC) — `/notifications` route. Groups by "Baru" (last 24h) and "Minggu ini"; empty state when none. Bell icon in `home_header.dart` now pushes here instead of opening a snackbar.

**5e — Access gating + cleanup**:
- `lib/src/features/expenses/record_expense_screen.dart` + `lib/src/features/incomes/record_income_screen.dart` — submit dot's `enabled` flag now ANDs in `ref.watch(canRecordTxnProvider)`. `view` users can open the screens but can't submit.
- `lib/src/ui/ft_action_sheet.dart` — `ActionChooserSheet` is now a `ConsumerWidget`. The action list is filtered by access level; "Catat Pengeluaran" + "Catat Pemasukan" need `canRecordTxn`; "Sesuaikan Aset" needs `canWriteAll`. View-only users see a one-line message instead of empty.
- `lib/src/ui/ft_ui.dart` — central FAB (`_CatatAktivitasFab`) becomes invisible when the user has no write permissions at all.
- `lib/src/router.dart` — added routes for `/profile/edit`, `/members/:memberId`, `/notifications`. Removed the `/insights` route + import (legacy analytics screen — Phase 4 already migrated home + Phase 5 menu to `/health`).
- `lib/src/features/home/home_screen.dart` — mounts `orphanedMembershipCleanupProvider`. The "insights" entry in the home menu now routes to `/health`.
- `lib/src/features/home/widgets/home_header.dart` — bell tap now pushes `/notifications`.

**5f — Docs**:
- `AGENTS.md` — replaced the "Roles: labels only for now" line with the new access-tier model: roles stay labels, `accessLevel` (`full`/`limited`/`view`) drives the actual gating; rules + Riverpod providers are the single source of truth.
- `SCHEMA.md` — updated `households/{hid}` to include `memberAccess: map<uid, level>` and `accessLevel` per member; updated `invites/{code}` to include `role` + `accessLevel`; replaced the inline rules sketch with a pointer to `firestore.rules`; bumped doc'd `schemaVersion` to 2 and noted the synchronization invariants for `memberIds` / `memberAccess` / `members[]`.

### Deviations from plan

- The plan called for two separate "remove member" + "change role" flows. We collapsed them into a single `/members/:memberId` screen with creator-only "Ubah akses" and "Keluarkan dari household" actions; the invite chips already cover initial role assignment so a separate role-change UI was redundant.
- `accessLevel` defaults to `full` (instead of `limited`) for the member created during `create(...)` — the creator must always have full access. Joiners default to whatever the invite specified (most invites default to `limited`).
- We did NOT add a Cloud Function to clean up `users/{uid}.householdId` when a creator removes a member; rules forbid it. Instead, the removed user's own client cleans up via `orphanedMembershipCleanupProvider`. This mirrors the existing `leave(...)` flow which the user runs themselves.
- `/insights` was removed entirely instead of redirected — the existing screen pre-dated the Phase 4 health screen and provided strictly less detail. Anything that linked to `/insights` (home menu) now points at `/health`.
- Member-management methods (`removeMember`, `updateMemberAccess`, `updateMyProfile`) were extracted into a Dart `part` file (`member_management.dart`) instead of a separate class so they retain access to `_db` / `_households` and the existing provider doesn't need to compose two repos.

### Verification

- `flutter analyze` → **10 issues**, all pre-existing info-level lints in code outside Phase 5 scope (unnecessary `ft_motion` imports in card / home / spend widgets, one unused `_runIncomes` declaration from earlier work, two const-ctor hints in `ft_ui.dart`, one unused `go_router` import in `income_log_screen.dart`). **0 new warnings, 0 errors from Phase 5.**
- File LOC after Phase 5 (all Phase 5 files under 400 ✓):
  - `household.dart`: 299; `household_repository.dart`: 361 (was 464, split via `member_management.dart` part file at 109 LOC); `household_providers.dart`: 86
  - `settings_screen.dart`: 307 (was 640); `widgets/members_section.dart`: 224; `widgets/household_section.dart`: 194; `widgets/settings_row.dart`: 130
  - `profile/edit_profile_screen.dart`: 188; `profile/widgets/edit_profile_parts.dart`: 366
  - `members/member_detail_screen.dart`: 196; `members/widgets/access_picker_sheet.dart`: 153; `members/widgets/member_detail_parts.dart`: 399; `members/invite_sheet.dart`: 281; `members/widgets/invite_sheet_parts.dart`: 246
  - `notifications/notification_providers.dart`: 164; `notifications/notifications_screen.dart`: 211
- Files still above 400 LOC after Phase 5 (none introduced by this phase — all pre-existing): `home/widgets/home_b_body.dart` 411, `investments/investments_screen.dart` 414, `expenses/expense_log_screen.dart` 416, `spend/spend_screen.dart` 422, `categories/category_detail_screen.dart` 450, `accounts/widgets/investasi_list.dart` 404, `ft_ui.dart` 775. None block Phase 5 acceptance; `ft_ui.dart` is intentionally a single chrome library.
- Rules sanity check (manual, against `firestore.rules`): `view` user trying to `update` an expense fails on `canTxn()`; `limited` user trying to `update` a card fails on `canFull()`; non-member trying to `list` households fails on the explicit `list` deny; non-member trying to `get` an invite by known code succeeds (needed for accept-invite preview).
