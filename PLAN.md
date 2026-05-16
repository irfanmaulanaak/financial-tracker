# Financial Tracker — Plan

Household financial tracker for Indonesian families. Flutter + Firebase. iOS + Android.

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

### Phase 0 — Skeleton (~2 days)
- `flutter create` + `flutterfire configure`
- Firebase Auth: email/password + Google sign-in
- Creator onboarding wizard:
  1. Household name
  2. Total monthly budget + payday (default 30)
  3. Review seeded categories (toggle + optional per-category budget; skippable)
  4. Invite first member (show one-time 6-digit code; skippable)
- Invited member: enter code → auto-join → home
- Invite codes: 6-digit numeric, unique, single-use, regenerated per invite
- Member list screen

### Phase 1 — Core Ledger (~1 week)
- Seeded categories + user-added (icon + color)
- Monthly budgets per category
- Record expense: amount, category, method, note, attributed-to-spender, date (backdate-able)
- Expense log: grouped by date; filter by member + category
- Home: month spend vs total budget, top categories with budget progress, recent 4-5 expenses

### Phase 2 — Money Model (~1-2 weeks)
- Cash accounts (manual balance)
- Savings accounts (manual)
- Credit cards (limit, used, due date, APR, owner)
- Edit asset sheet (set or delta)
- Record income (source, destination account)
- Income → bumps destination account
- Expense from CC → bumps `card.used`
- Net worth on dashboard

### Phase 3 — Indonesian Differentiator (~2-3 weeks)
- Cicilan plans at point-of-sale (1/3/6/12 months, APR math)
- Active installment tracking per card
- Cards screen: per-card detail + installments list
- Pay minimum / pay full actions

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
- Firestore collection layout (households embed vs subcollection; expense + member + invite structure) — **next step**
- State management pick — default Riverpod; confirm during scaffolding
- Offline storage — skip local DB; rely on Firestore built-in offline cache (sufficient for 2-5 users)

## Next Step
Sketch Firestore data model for Phase 0 + 1, then `flutter create` + `flutterfire configure`.
