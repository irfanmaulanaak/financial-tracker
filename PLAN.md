# Financial Tracker — Plan

Household financial tracker for Indonesian families. Flutter + Firebase. iOS + Android.

## Setup Status (current)
- ✅ Flutter project scaffolded (`financial_tracker`, org `com.irfanmaulanaakbar`)
- ✅ Firebase project: `financial-tracker-4791d` — Android + iOS + Web apps registered
- ✅ `lib/firebase_options.dart` generated (committed; safe by design — protection comes from Rules)
- ✅ Packages installed: firebase_core, firebase_auth, cloud_firestore, google_sign_in, flutter_riverpod, go_router, intl
- ✅ `main.dart` initializes Firebase + Riverpod ProviderScope
- ✅ `flutter analyze` clean
- ✅ Firestore Security Rules deployed (`firestore.rules`, `firestore.indexes.json`, `.firebaserc`)
- ✅ Phase 0 done (auth, onboarding, invite, members) — email/password only; Google sign-in deferred
- ✅ Phase 1 done (categories CRUD, expenses, log w/ filters, home dashboard)
- ✅ Phase 2 done (cash/savings accounts, income with transactional account bump, credit cards CRUD, CC expense bumps card.used, net worth widget on home)
- ✅ Phase 3 done (cicilan POS plans 3/6/12/24 with flat-rate APR, installment subcollection, pay-minimum / pay-full transactions, card detail screen)
- ✅ Tests: 44 Dart unit tests + 45 emulator integration tests, all green
- ⏭ Next: Phase 4 (health score, category analysis, charts)

## Stack
- Flutter 3.41.9 stable
- Firebase: Auth (email/password + Google) + Firestore
- Targets: iOS + Android primary; web optional (Flutter web later)
- Locale: id-ID; IDR only
- TBD: state (Riverpod likely), routing (go_router), charts (fl_chart + CustomPainter)

## Product Model
- Household-first; one household per user (MVP)
- Expenses: family-owned, attributed to spender, counted vs shared budget
- Income: family-owned, lands in destination account
- Cards: per-member owned, visible to household
- Categories & budgets: shared; seeded defaults + user-added
- Goals: shared OR personal (both)
- Assets: pooled (no per-member breakdown)
- Health score: household level
- Roles (Istri/Suami/Anak): labels only

## Rules & Defaults
- Budget cycle: payday-based. Default payday = 30th of month; if 30th is Sat/Sun → last weekday of month. Period: payday → day before next payday. (Configurable per household later; MVP hardcoded.)
- Default categories (7, editable + extensible): Makanan & Minuman, Tagihan & Utilitas, Belanja, Transportasi, Hiburan, Kesehatan, Lainnya
- Expense date: any past date, no limit
- Recurring flag: per-expense + per-income, user-toggled. Metadata only in Phase 1-3; auto-create in Phase 5.
- Payment methods: seeded defaults (Tunai, BCA Debit, GoPay, OVO, etc.) + household can add custom.
- Account transfers: skip MVP. Edit each account balance manually.
- Daily budget: derived as `monthly budget ÷ days in cycle`. Display-only on home.
- Invite code: 6-digit numeric, unique per invitation, one-time use, regenerated for each new invite. No stable household-wide code.
- Onboarding (creator): step-by-step wizard.
- Onboarding (invited member): enter code → auto-join → home.
- Notifications: in-app indicators only in MVP. Push deferred to Phase 5 (no email).

## Scope Constraints
- Currency: IDR only; locale `id-ID` for dates + numbers
- Multi-household per user: never (1 user = 1 household)
- Member exit:
  - Members can leave themselves
  - Creator can remove other members
  - If creator leaves → first remaining member auto-becomes creator
  - If last member leaves → household + all data deleted
- Export/backup: skip MVP
- Distribution: internal (TestFlight + APK direct install). No public App Store / Play Store. (No Apple Sign-in required.)

## Phases

### Phase 0 — Skeleton (~2 days) ✅
- ✅ `flutter create` + `flutterfire configure`
- ✅ Firebase packages + main.dart init
- ✅ Deploy Firestore Security Rules (from SCHEMA.md)
- ✅ go_router scaffold + auth-aware redirect (auth → onboarding → home)
- ✅ Firebase Auth: email/password — **Google sign-in deferred** (needs OAuth client setup; v7 API changes)
- ✅ Creator onboarding wizard (4 steps):
  1. Household name + creator role
  2. Total monthly budget + payday
  3. Review seeded categories + optional per-category budget
  4. Invite first member (one-time 6-digit code)
- ✅ Invited member: enter code → join transaction → home
- ✅ Invite codes: 6-digit numeric, single-use, regenerated per invite
- ✅ Member list screen + leave/auto-promote-creator + invite-from-list

### Phase 1 — Core Ledger ✅
- ✅ Seeded categories (7) + user-added (icon + color picker)
- ✅ Monthly budgets per category
- ✅ Archive/unarchive category
- ✅ Record expense: amount, category, method, note, attributed-to-spender, date (backdate-able), recurring flag
- ✅ Expense log: grouped by day, current cycle only, filter by member + category, swipe/long-press delete
- ✅ Home: cycle spend vs total budget, daily budget, top categories with progress bars, recent 5 expenses

### Phase 2 — Money Model ✅
- ✅ Cash accounts (embedded on household; set + delta + add + delete)
- ✅ Savings accounts (same model)
- ✅ Credit cards (subcollection; limit, used, dueDay, APR, owner, accent, minPaymentPct)
- ✅ Edit asset sheet (set mode + signed delta mode)
- ✅ Record income (source, destination, receivedBy, backdate, recurring flag)
- ✅ Income → atomic transaction bumps destination cash/savings account
- ✅ Expense from CC → atomic transaction bumps `card.used`
- ✅ Net worth widget on home (cash + savings − card debt)

### Phase 3 — Indonesian Differentiator ✅
- ✅ Cicilan plans at POS (3/6/12/24 months, flat APR + effective amortising)
- ✅ Atomic transaction creates expense + installment doc + bumps card.used by plan.total
- ✅ Active installment tracking per card with monthsPaid progression
- ✅ Cards screen: list with limit/used bar + per-card detail view
- ✅ Pay minimum (with floor) / pay full actions, both transactional
- Note: pay-min hits `card.used` directly; doesn't auto-link to specific installments (kept simple per AGENTS.md). User taps "Tandai dibayar" per installment to advance monthsPaid.

### Phase 4 — Intelligence (later)
- Health score (5 factors, weights sum 100):
  - Disiplin pengeluaran 30% (budget adherence)
  - Rasio menabung 25% (savings rate = (income − spend) / income)
  - Dana darurat 20% (em-fund balance ÷ avg monthly spend)
  - Beban utang 15% (debt-to-income)
  - Diversifikasi investasi 10%
  - MVP fallback: start with simple `spend / income` ratio if full formula not ready
- Category analysis (vs 3-month avg, daily pattern, verdict)
- Spend chart (monthly donut, per-category breakdown)
- Allocation recommendation → **TODO / deferred**. Financial-advice risk; revisit only if explicitly requested.

### Phase 5 — Polish
- Goals tracking (shared + personal)
- Investments (manual positions)
- Recurring transactions (Cloud Function)
- Notifications (due date, budget warning)
- Export CSV/PDF
- Bank/e-wallet auto-import (large initiative; deferred)
- Flutter web build

## Open Decisions (remaining)
- ~~Firestore collection layout~~ → captured in `SCHEMA.md`
- ~~State management~~ → Riverpod (3.x) locked in
- Offline storage — skip local DB; rely on Firestore built-in offline cache (sufficient for 2-5 users)

## Tests
- **Unit** (`test/unit/` — pure Dart, `flutter test`):
  - `payday_test.dart` — weekend-rollback, current cycle math, day count
  - `invite_code_test.dart` — 6-digit gen, leading zeros, validation, normalisation
  - `formatters_test.dart` — IDR format/parse, id-ID dates, dayKey
  - `expense_aggregations_test.dart` — totalSpent, byCategory, byMember, groupByDay, topCategories, dailyBudget
  - `cicilan_test.dart` — flat-rate + effective APR cicilan math, 0% promo, edge cases, minimumPayment floor/cap
  - `net_worth_test.dart` — cash+savings-debt, CardBalance.available clamp, applyDelta clamp
- **Emulator integration** (`emulator_tests/` — real Firestore protocol, no mocks):
  - `users.test.js` — per-user doc isolation
  - `households.test.js` — create/read/update rules, self-join structural check, subcollection gating
  - `invites.test.js` — read/create/update/delete rules, consumed-locking
  - `flows.test.js` — Phase 0/1 flows: household create, second-household guard, invite + join happy path, unknown/consumed/expired/already-in-household guards, expense subcollection
  - `accounts.test.js` — Phase 2: cash account add + applyDelta clamp, income tx bumps cash OR savings account, rejects ghost destination
  - `cards.test.js` — Phase 2/3: card CRUD rules, CC expense tx bumps `card.used`, ghost card guard, 0% + flat-rate cicilan creation (expense + installment + card.used += total), pay-min with pct/floor, pay-full, installment monthsPaid increment
- **Run**: `flutter test` for unit; `cd emulator_tests && npm install && cd .. && firebase emulators:exec --only firestore --project demo-ft "cd emulator_tests && npm test"` for integration

## Next Step
Phase 4 — intelligence: household health score (5-factor weighted), category analysis (vs 3-month avg, daily pattern), spend chart (donut + per-category breakdown).
