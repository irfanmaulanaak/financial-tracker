# FinSist — Plan

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
- ✅ Phase 4 done (5-factor weighted health score, per-category 3-cycle analysis, spend donut, insights screen)
- ✅ Phase 5 done (goals shared+personal, manual investments, client-side recurring materialisation, CSV export via share sheet, in-app budget/due-date banners)
- ✅ Auth expanded (email/password + Google + email-link passwordless, all three on the same redesigned editorial auth screens)
- ✅ Visual refresh (warm cream editorial theme matching `claude-design/`: Newsreader serif + Inter sans, clay/sage/moss palette, custom `FtColors`, reusable `Eyebrow`)
- ✅ CI: GitHub Actions `build` workflow — analyze + unit tests on every PR; release APKs (split-per-ABI) on `main` + tag-triggered GH Release attach
- ✅ Tests: 104 Dart unit tests + 63 emulator integration tests, all green
- ✅ Hardening pass: invite-bound self-join rules (require claimed invite + same-tx consume via `getAfter`), recurring runner wired on home mount, expense delete reverses `card.used` and removes installments, income delete reverses destination account, last-member leave purges all subcollections, oversized UI files split into per-widget modules
- ⏭ Next: TestFlight distribution + Phase 5 deferred items (push notifications, Cloud Function recurring, web build) only if needed

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
- Daily budget: derived as `current-cycle income ÷ days in cycle`. Display-only on home. Income is the spending ceiling; dashboard warns when expenses approach/exceed recorded income.
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
- ✅ Firebase Auth: email/password + **Google sign-in (google_sign_in 7.x)** + **email-link passwordless** (paste-link-back UX, no Universal/App Links plumbing)
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
- ✅ Home: cycle spend vs current-cycle income, income-based daily budget, top categories with progress bars, recent 5 expenses

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

### Phase 4 — Intelligence ✅
- ✅ Health score (5 factors, weights sum 100, missing factors redistribute):
  - Disiplin pengeluaran 30% (budget adherence)
  - Rasio menabung 25% (savings rate)
  - Dana darurat 20% (savings ÷ 6 × avg monthly spend)
  - Beban utang 15% (1 − card debt ÷ 6 × income)
  - Diversifikasi investasi 10% (# distinct positions / 5)
- ✅ Category analysis (current cycle vs avg of previous 3 cycles → Lebih hemat / Stabil / Boros / Sangat boros)
- ✅ Daily-pattern helper (Mon..Sun share, pure)
- ✅ Spend donut (fl_chart) + legend with percentage share
- ✅ Insights screen wired in home menu
- Allocation recommendation → **deferred** (financial-advice risk)

### Auth & Visual ✅
- ✅ Three sign-in methods on a single editorial auth shell:
  - Email + password (Firebase Auth)
  - Google (google_sign_in 7.x; native sheet → idToken → `signInWithCredential`)
  - Email link passwordless (`sendSignInLinkToEmail` → user pastes URL back → `signInWithEmailLink`)
- ✅ `AuthShell` + `LabeledField` + `AuthErrorBanner` + `OrDivider` shared widgets (`lib/src/features/auth/auth_shell.dart`)
- ✅ Hand-painted Google "G" mark (`_GoogleGPainter`) — no asset bundled
- ✅ Theme refresh (`lib/src/theme.dart`): `FtColors` palette (clay/sage/moss/plum/ochre/danger/sky + 4 ink levels + 2 line tints), Newsreader serif for display + Inter for body via `google_fonts`, custom Material 3 `ColorScheme` mapped to warm cream surfaces, default Card / InputDecoration / FilledButton / OutlinedButton themes, reusable `Eyebrow` widget
- ✅ Idempotent `_ensureUserDoc` upsert on every sign-in path so existing `householdId` is never clobbered

### Phase 5 — Polish ✅
- ✅ Goals: shared + personal scope, target/current/dueDate/monthlyContrib, contribute tx clamps to target, monthsToGoal + requiredMonthlyContribution pure helpers, full CRUD UI
- ✅ Investments: manual positions per type (saham/reksadana/deposito/crypto/emas/lainnya), gain + portfolio summary helpers, mark-to-market update, feeds health score's diversifikasi factor
- ✅ Recurring materialisation: client-side `datesToMaterialise` + `latestPerKey` helpers (full-month gap detection, day-clamp on shorter months, year-boundary safe). Cloud Function path skipped per AGENTS.md ("no over-engineering" for 2-5 users).
- ✅ In-app indicators: income-spend banner (≥80% warning, ≥100% exceeded) + CC due-date banner (≤5 days). Push notifications deferred.
- ✅ Export: CSV builder (RFC 4180-ish quoting), share-sheet via `share_plus` for expenses (90d) + income (500 latest).
- PDF export → **deferred** (CSV opens in Excel/Numbers/Sheets, sufficient for internal use)
- Bank/e-wallet auto-import → **deferred** (large initiative)
- Flutter web build → **deferred** (iOS + Android only per Stack)

## Open Decisions (remaining)
- ~~Firestore collection layout~~ → captured in `SCHEMA.md`
- ~~State management~~ → Riverpod (3.x) locked in
- Offline storage — skip local DB; rely on Firestore built-in offline cache (sufficient for 2-5 users)

## Tests
- **Unit** (`test/unit/` — pure Dart, `flutter test`) — 104 tests:
  - `payday_test.dart` — weekend-rollback, current cycle math, day count
  - `invite_code_test.dart` — 6-digit gen, leading zeros, validation, normalisation
  - `formatters_test.dart` — IDR format/parse, id-ID dates, dayKey
  - `expense_aggregations_test.dart` — totalSpent, byCategory, byMember, groupByDay, topCategories, dailyBudget
  - `cicilan_test.dart` — flat-rate + effective APR cicilan math, 0% promo, edge cases, minimumPayment floor/cap
  - `net_worth_test.dart` — cash+savings-debt, CardBalance.available clamp, applyDelta clamp
  - `health_score_test.dart` — Phase 4: 5-factor scoring, weight redistribution when data missing, verdict bands, clamp behaviour
  - `category_analysis_test.dart` — Phase 4: verdict thresholds, new-this-cycle handling, daily pattern shares
  - `goals_test.dart` — Phase 5: progress + remaining + isComplete, monthsToGoal rounding/null, requiredMonthlyContribution
  - `investments_test.dart` — Phase 5: gain/gainPct, portfolio summary with distinct-type counting
  - `recurring_test.dart` — Phase 5: full-month detection, jan-31→feb-28 clamp, year boundary, latestPerKey
  - `csv_export_test.dart` — Phase 5: RFC 4180 escaping, expense rows with ISO dates
  - `in_app_indicators_test.dart` — Phase 5: budget bands (80/100%), due-date warn window + month rollover + day clamp
- **Emulator integration** (`emulator_tests/` — real Firestore protocol, no mocks) — 54 tests:
  - `users.test.js` — per-user doc isolation
  - `households.test.js` — create/read/update rules, self-join structural check, subcollection gating
  - `invites.test.js` — read/create/update/delete rules, consumed-locking
  - `flows.test.js` — Phase 0/1 flows: household create, invite + join happy path + guards, expense subcollection gating
  - `accounts.test.js` — Phase 2: account add + applyDelta clamp, income tx bumps cash/savings account, ghost destination guard
  - `cards.test.js` — Phase 2/3: card CRUD rules, CC expense + cicilan tx (card.used += plan.total), pay-min/full, installment monthsPaid
  - `goals.test.js` — Phase 5: shared + personal add, non-member denied, contribute tx clamps to target, delete
  - `investments.test.js` — Phase 5: position add/read/update/delete, non-member denied
- **Run**: `flutter test` for unit; `cd emulator_tests && npm install && cd .. && firebase emulators:exec --only firestore --project demo-ft "cd emulator_tests && npm test"` for integration

## CI / Distribution
- `.github/workflows/build.yml`:
  - Job `test` — `flutter analyze` + `flutter test` on every push / PR to `main`
  - Job `android` — `flutter build apk --release --split-per-abi` → uploads APKs as workflow artifacts (`financial-tracker-apks-<sha>`, 30 day retention)
  - On `v*` tags → additionally attaches APKs to a GitHub Release with auto-generated notes
  - Flutter pinned to 3.41.9 stable; Temurin JDK 17
  - No signing config: builds use the debug keystore baked into Flutter (fine for internal sideloading). Add an upload keystore + secrets when distributing more widely.

## Next Step
MVP scope complete. Remaining work is distribution (TestFlight + APK sideload via GH Release) and the deferred items called out per phase. No further phases planned.
