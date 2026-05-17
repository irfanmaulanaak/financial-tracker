# Refactor Plan: Apply `claude-design` Across All Pages

## Context

The user mocked up a new design system + screens in `claude-design/design/` (React/JSX prototypes from claude.ai/design). The job is to **port these designs pixel-perfectly into the existing Flutter app** and add the new features they introduce.

The current Flutter app is already structurally close to the new design:
- Same 5-tab bottom nav (`/home`, `/spend`, `/accounts`, `/goals`, `/cards`).
- Same warm-editorial palette (clay/sage/moss/plum/ochre/sky/danger), ink/line tokens — already centralized in `lib/src/theme.dart`.
- Same motion idiom (fade-up, tap-scale, haptics) — in `lib/src/ui/ft_motion.dart`, `ft_haptics.dart`.
- Same overall product model (household-first, IDR-only, Riverpod + Firestore).

So this is primarily a **visual refresh + selective new features**, not a rewrite. We keep the data layer, repositories, providers, business logic (payday, health score, cicilan, recurring runner), and motion/haptic primitives. We restyle screens and add the new pieces.

### User decisions (locked)
- **Scope**: Full parity with the new design — all new screens & features.
- **Typography**: Switch sans from Inter → Geist (Newsreader for serif unchanged).
- **Household access tiers**: Implement real 3-tier access control (full/limited/view-only). This **supersedes** the current `AGENTS.md` line that says "Roles: labels only, no permission gating." Update `AGENTS.md` as part of this plan.
- **Dark mode**: Parity on both themes for every restyled screen.

## Approach

Five phases, in order. Each phase ships independently so review is tractable. Most existing files get edited in place; new screens get new files. Stick to AGENTS.md's <400 LOC per file — split as needed.

---

### Phase 1 — Design tokens & shared widgets

**Goal**: Update the design-system layer so all later screens get the right look "for free."

**Files to edit:**
- `lib/src/theme.dart`
  - Swap `GoogleFonts.interTextTheme()` → `GoogleFonts.geistTextTheme()` (sans). Keep `newsreaderTextTheme()` for serif.
  - Add category colors as static accessors on `FtColors`: `catFood`, `catTransport`, `catBills`, `catShopping`, `catEntertainment`, `catHealth`, `catOther` (hex values in `claude-design/design/theme.jsx`).
  - Bump default card radius 14 → 18 (matches `Card({ r: 18 })` in `widgets.jsx`).
  - Add a small font-feature helper (`ss01` on sans, kern+liga on serif) via `TextStyle.fontFeatures`.
- `lib/src/ui/ft_ui.dart`
  - `FtCard`: radius 14 → 18; keep API.
  - `FtSectionHeader`: leave; matches `Eyebrow`-style header in design.
  - `FtProgressBar`: confirm overflow color path matches design's `overflowColor` semantics on `Bar`.
- `pubspec.yaml`: confirm `google_fonts` resolves Geist; if not, fall back to bundling Geist `.ttf` under `assets/fonts/`. Verify by running `flutter pub get`.

**Files to add** (new shared widgets used across many screens):
- `lib/src/ui/ft_donut.dart` — `FtDonut({ segments, size, thickness, centerLabel, centerValue })`. CustomPainter; segments = `[(value, color)]`.
- `lib/src/ui/ft_ring.dart` — `FtRing({ value, max, size, thickness, color, track })` 0..1 gauge.
- `lib/src/ui/ft_sparkline.dart` — `FtSparkline({ data, color, fill })` for home asset trend.
- `lib/src/ui/ft_traffic_light.dart` — `FtTrafficLight({ state, vertical })` glowing 3-state indicator.
- `lib/src/ui/ft_monthly_bars.dart` — `FtMonthlyBars({ months })` stacked monthly bars (spend screen historical view).
- `lib/src/ui/ft_chip.dart` — soft/solid chip badge (already partially in screens; extract).
- `lib/src/ui/ft_glass_pill.dart` — iOS-style backdrop-filter pill used in nav bar and tab bar (use `BackdropFilter` + `ImageFilter.blur`).
- `lib/src/ui/ft_keypad.dart` — extract 12-key numeric keypad currently duplicated in `record_expense_screen.dart` and `record_income_screen.dart` (resolves [ISSUES.md#8](../../Developer/financial-tracker/ISSUES.md)).
- `lib/src/ui/ft_amount_display.dart` — large serif amount + blinking cursor (also duplicated; resolves part of [ISSUES.md#7](../../Developer/financial-tracker/ISSUES.md)).
- `lib/src/ui/ft_member_avatar.dart` — circular member avatar with initials + ring + pending fade.
- `lib/src/ui/ft_member_chip.dart` — inline name+dot chip used on expense rows.

**Verification for Phase 1:**
- `flutter analyze` clean.
- Run app; visit home — fonts updated; existing layouts otherwise unchanged.
- Toggle dark mode; verify category color set has both light/dark variants.

---

### Phase 2 — Home / Beranda

**Goal**: Match `screens-home.jsx` — denser hero with total assets, side-by-side spend/health, category strip, cards/goals previews, recent list with member chips.

**Files to edit:**
- `lib/src/features/home/home_screen.dart` — restructure body order to match new design.
- `lib/src/features/home/widgets/home_header.dart` — initials avatar + name/household + member stack + bell.
- `lib/src/features/home/widgets/net_worth_section.dart` → repurpose into "Total Asset" hero card with mini donut + sparkline + 3-column breakdown. Reuses new `FtDonut`, `FtSparkline`.
- `lib/src/features/home/widgets/health_snapshot.dart` → side-by-side spend/health card using `FtTrafficLight`.
- `lib/src/features/home/widgets/category_grid.dart` → 2×2 dense grid with progress bar + budget status.
- `lib/src/features/home/widgets/cards_preview.dart` → proportional stacked bar across cards + nearest due date.
- `lib/src/features/home/widgets/goals_preview.dart` → 3-goal preview with ring/percentage.
- `lib/src/features/home/widgets/recent_list.dart` → add member chip column when household has >1 member; uses `FtMemberChip`.

**Verification:**
- Home renders top-to-bottom in new order; visit in light + dark.
- Tap member stack → settings (members section). Tap bell → notifications (Phase 5).

---

### Phase 3 — Core ledger screens (Spend, Category, Expenses, Add Expense, Cards, Add Card Pay)

**Goal**: Restyle the heaviest screens and split oversize ones.

**Files to edit:**
- `lib/src/features/spend/spend_screen.dart` (422 LOC, fits limit) — hero donut + month tabs (Feb/Mar/Apr/Mei) + clickable category list. Add `FtMonthlyBars` block for historical view.
- `lib/src/features/categories/category_detail_screen.dart` — hero with progress bar, analysis card (vs 3-cycle avg, 14-day mini bars, traffic-light verdict), recent transactions. Reuses existing `category_analysis.dart`.
- `lib/src/features/expenses/expense_log_screen.dart` — total-today card + horizontal member filter chips + category filter chips + day-grouped list. Wire member filter to existing `expenseRecords` provider.
- `lib/src/features/cards/cards_screen.dart` (677 LOC — **split**) — hero accumulation card + per-card section (gradient card visual, installments list with progress, pay min / pay full buttons), tips card. Split per-card UI into `lib/src/features/cards/widgets/card_tile.dart` and installment list into `lib/src/features/cards/widgets/installment_list.dart` to land under 400 LOC.
- `lib/src/features/cards/card_detail_screen.dart` — restyle to match per-card section idiom; keep behavior.

**Files to split** (resolves [ISSUES.md#7](../../Developer/financial-tracker/ISSUES.md), [ISSUES.md#8](../../Developer/financial-tracker/ISSUES.md)):
- `lib/src/features/expenses/record_expense_screen.dart` (1,122 LOC). New folder `lib/src/features/record_common/` with:
  - `amount_display.dart` (re-exports `FtAmountDisplay`)
  - `keypad.dart` (re-exports `FtKeypad`)
  - `category_chip_row.dart`
  - `payment_method_row.dart`
  - `installment_picker.dart` (cicilan plan grid + APR preview)
  - `recurring_toggle.dart`
- Slim `record_expense_screen.dart` to orchestration only.
- `lib/src/features/incomes/record_income_screen.dart` (655 LOC) — switch to the same `record_common/` widgets; restyle to match `screens-actions.jsx` (source chips, destination account selector, recurring toggle, savings ratio hint).

**Files to add:**
- `lib/src/features/cards/pay_card_sheet.dart` — bottom sheet with Min/Full/Custom options + keypad for custom (matches `PayCardSheet` in `screens-extras.jsx`). Wire to `card_repository.dart` pay flow.

**Verification:**
- Record expense → cash and credit-card paths both work; cicilan preview matches `cicilan.dart` calc.
- Tap a card "Bayar minimum"/"Bayar penuh"/"Jumlah lain" → sheet → payment recorded; card `used` decremented; account balance decremented.
- `flutter analyze` clean; no file >400 LOC except acceptable exceptions documented in the PR.

---

### Phase 4 — Assets / Allocation, Goals, Health

**Goal**: New asset allocation tab, goal presets + auto-debit, full health detector screen.

**Files to edit:**
- `lib/src/features/accounts/accounts_screen.dart` (635 LOC — **split**) — hero card with composition bar + 3-column delta; 4 tabs: Tunai, Tabungan, Investasi, Alokasi. Split each tab body into:
  - `widgets/cash_tab.dart`
  - `widgets/savings_tab.dart`
  - `widgets/investasi_list.dart` (exists; restyle to match design rows)
  - `widgets/alokasi_tab.dart` (exists; rewrite — see below)
- `lib/src/features/accounts/widgets/alokasi_tab.dart` — Allocation tab: global context card, current-vs-recommended donut + toggle, rebalancing moves list. Backed by a new pure function in `lib/src/core/allocation_recommendation.dart` (target weights per asset class + reasoning). No live market feed; mirror `data.jsx`'s static allocation shape.
- `lib/src/features/goals/goals_screen.dart` — restyle list with colored icon badge + tone-colored progress + warning card if behind schedule.
- `lib/src/features/goals/goal_detail_screen.dart` — large ring hero + 3-col grid + 8-month bar history + projection text + "Sesuaikan" / "+ Setor Sekarang" actions. Use new `FtRing`.
- `lib/src/features/insights/insights_screen.dart` (792 LOC — **split & relocate**) — current "health" content moves into the new dedicated health screen. Keep `insights_screen.dart` only if used elsewhere (else delete in Phase 5).

**Files to add:**
- `lib/src/features/goals/widgets/goal_preset_grid.dart` — 3×2 preset cards (Dana Darurat / Liburan / Rumah / Gadget / Pernikahan / Lainnya).
- `lib/src/features/goals/add_goal_screen.dart` — full add-goal flow: preset → name + color → target + current → duration → projection → source account → auto-debit toggle → keypad.
- `lib/src/features/goals/goal.dart` — extend model: `autoDebit: bool`, `autoDebitDay: int`, `sourceAccountId: String?`, `presetId: String?`. Update `goal_repository.dart` + Firestore schema.
- `lib/src/features/goals/auto_debit_runner.dart` — client-side runner (parallel to existing `recurring_runner.dart`), idempotent per `(goalId, month)`. Mounts from home, same pattern.
- `lib/src/core/allocation_recommendation.dart` — pure function: given investments, return current + target allocation segments and rebalancing moves.
- `lib/src/features/health/health_screen.dart` — new dedicated screen wired to `/health`. Hero (vertical traffic light + score), summary box, component breakdown (5 weighted factors from existing `health_score.dart`), spending findings (category deltas from `category_analysis.dart`), recommendations.
- `lib/src/router.dart` — add `/health` route; redirect home's health card to it.

**Verification:**
- Set a goal with auto-debit; cross a month boundary; confirm a single transfer materializes (not duplicated across devices — same deterministic-doc-ID strategy as [ISSUES.md#2](../../Developer/financial-tracker/ISSUES.md)).
- Allocation tab shows current vs recommended; toggle works; moves list reads sensible.
- Health screen renders score, factors, findings; tapping a finding → category detail.

---

### Phase 5 — Profile, Members, Notifications, Settings, Access Control

**Goal**: New profile/member/notification screens + real access-tier enforcement.

**Files to edit:**
- `lib/src/features/settings/settings_screen.dart` (640 LOC — **split**) — user card + members section + display section + account/security rows + logout. Members section moves to:
  - `widgets/members_section.dart` — shared wallet toggle + member rows + "Undang Anggota" CTA.
- `lib/src/features/members/member_list_screen.dart` — keep or fold into `members_section.dart` if duplicate.
- `lib/src/features/members/invite_sheet.dart` — extend with role chips (Suami/Istri/Anak/Orang Tua/Lainnya) **and** access-tier selector (Akses Penuh / Akses Terbatas / Lihat Saja).
- `lib/src/features/household/household.dart` — add `accessLevel: 'full' | 'limited' | 'view'` to each member. Persisted under `households/{hid}.members[].accessLevel`.
- `lib/src/features/household/household_repository.dart` — write access level on invite acceptance; expose creator-only `removeMember` (resolves [ISSUES.md#1](../../Developer/financial-tracker/ISSUES.md)).
- `firestore.rules` — gate writes by access level:
  - `full` → all writes (expenses, incomes, cards, goals, settings).
  - `limited` → expenses + incomes only; no settings/members/cards/goals writes.
  - `view` → no writes; reads only.
  - Also restrict household root + invite reads to members (resolves [ISSUES.md#3](../../Developer/financial-tracker/ISSUES.md)).
- `AGENTS.md` — update "Roles: labels only, no permission gating" line to reflect the new model.
- `SCHEMA.md` — document `accessLevel` field.

**Files to add:**
- `lib/src/features/profile/edit_profile_screen.dart` — avatar preview, color picker, name/email/phone fields, security rows, delete-account button. Route `/profile/edit`.
- `lib/src/features/members/member_detail_screen.dart` — member hero, pending hint, contact card, access-level card, activity stats, destructive actions (resend invite / cancel invite / remove). Route `/members/:memberId`.
- `lib/src/features/notifications/notifications_screen.dart` — grouped (Baru / Minggu ini) list. Sources: budget over-warnings (`in_app_indicators.dart`), recent member activity (Firestore stream), CC due in ≤5d, goal milestones, invite acceptances, allocation rebalance suggestions. Route `/notifications`.
- `lib/src/features/notifications/notification_providers.dart` — derive notification feed from existing providers; no new collection needed for MVP.
- `lib/src/router.dart` — add `/profile/edit`, `/members/:memberId`, `/notifications`, `/health`.

**Verification:**
- Sign in as a "limited" member → expense entry works; settings rows are visible but disabled / show "tidak punya akses" toast.
- Sign in as "view" → keypad disabled, action buttons hidden.
- Sign in as creator → can remove a member; removed user is signed-out on next session.
- Notifications: trigger an over-budget category and a CC due-in-3-days; both appear in the screen.
- Edit profile → save → name/color reflected in member avatar across app.

---

## File map summary

**Edited (existing):** `lib/src/theme.dart`, `lib/src/ui/ft_ui.dart`, `lib/src/router.dart`, all `lib/src/features/{home,spend,expenses,incomes,cards,accounts,goals,categories,settings,members,household}/*_screen.dart` and their `widgets/`, `pubspec.yaml`, `firestore.rules`, `AGENTS.md`, `SCHEMA.md`.

**New:**
- `lib/src/ui/`: `ft_donut.dart`, `ft_ring.dart`, `ft_sparkline.dart`, `ft_traffic_light.dart`, `ft_monthly_bars.dart`, `ft_chip.dart`, `ft_glass_pill.dart`, `ft_keypad.dart`, `ft_amount_display.dart`, `ft_member_avatar.dart`, `ft_member_chip.dart`.
- `lib/src/features/record_common/`: `amount_display.dart`, `keypad.dart`, `category_chip_row.dart`, `payment_method_row.dart`, `installment_picker.dart`, `recurring_toggle.dart`.
- `lib/src/features/cards/pay_card_sheet.dart`, `widgets/card_tile.dart`, `widgets/installment_list.dart`.
- `lib/src/features/goals/add_goal_screen.dart`, `widgets/goal_preset_grid.dart`, `auto_debit_runner.dart`.
- `lib/src/features/health/health_screen.dart`.
- `lib/src/features/profile/edit_profile_screen.dart`.
- `lib/src/features/members/member_detail_screen.dart`.
- `lib/src/features/notifications/notifications_screen.dart`, `notification_providers.dart`.
- `lib/src/features/accounts/widgets/{cash_tab.dart,savings_tab.dart}`.
- `lib/src/core/allocation_recommendation.dart`.

## Existing utilities to reuse (do not reinvent)
- `lib/src/core/payday.dart` — cycle math.
- `lib/src/core/formatters.dart` — IDR + date formatting.
- `lib/src/core/health_score.dart` — 5-factor scoring (feeds the new health screen).
- `lib/src/core/category_analysis.dart` — vs-3-cycle average (feeds category detail + health findings).
- `lib/src/core/cicilan.dart` — installment math (feeds installment_picker + cards screen).
- `lib/src/core/recurring_runner.dart` — pattern to copy for new `auto_debit_runner.dart`.
- `lib/src/core/in_app_indicators.dart` — budget warnings + CC due (feeds notifications).
- `lib/src/core/expense_aggregations.dart` — totals, top categories (feeds home + spend + member filter).
- `lib/src/core/net_worth.dart` — cash + savings − card debt (feeds home asset hero).
- `lib/src/ui/ft_motion.dart` — `FtFadeUp`, `FtTapScale`, `ftFadeUpPage` (keep on all transitions).
- `lib/src/ui/ft_haptics.dart` — tap/select/warning (keep on all interactive elements).
- `lib/src/ui/ft_action_sheet.dart` — `showFtActionSheet`, `ActionChooserSheet` (already matches design's bottom-sheet idiom).

## Out of scope
- Renaming routes (`/accounts` → `/assets`) — current names work; new design route names are React-internal, not user-facing.
- Liquid-glass keyboard mockup from `IOSKeyboard` — native Flutter keyboards stay.
- iOS device frame chrome — the design renders a virtual iOS frame for prototype review; not a real-app concern.
- Notification push delivery — the new notifications screen is an in-app feed only. Push deferred.
- Editing security (2FA, sessions, password change) shown in `screens-profile.jsx` Security section — render as static rows for now; wiring to Firebase Auth deferred.

## Verification (end-to-end)

After all phases:
1. `flutter analyze` → "No issues found".
2. `flutter test` → all existing tests pass; add regression tests for `allocation_recommendation.dart` and `auto_debit_runner.dart` (per AGENTS.md: "Bugs: add regression test when it fits").
3. `flutter run` on iOS simulator. Walk every tab + new screen in **both light and dark**:
   - Home → tap member stack → settings → invite a "limited" member.
   - Spend → tap category → category detail → traffic-light verdict matches `category_analysis.dart`.
   - Add expense → cash → save; add expense → credit card with 6-month cicilan → save.
   - Cards → pay min / pay full / custom → balance updates correctly.
   - Accounts → Alokasi tab → toggle Sekarang / Direkomendasikan; moves render.
   - Goals → create with auto-debit → next month, transfer appears.
   - Health → score + factors render; tap a finding → category detail.
   - Profile → edit name + color → see changes propagate to avatar everywhere.
   - Notifications → over-budget, CC due, goal milestone all surface.
4. Firestore rules: deploy to emulator; run access-tier tests (full / limited / view) for each write path.
5. Confirm no file >400 LOC (`find lib -name "*.dart" -exec wc -l {} + | sort -n | tail`).
