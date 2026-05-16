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

## Phases

### Phase 0 — Skeleton (~2 days)
- `flutter create` + `flutterfire configure`
- Firebase Auth: email/password + Google sign-in
- Create household
- Invite: email + 6-digit join code
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
- Health score (rule-based: savings rate, debt/income, budget adherence, emergency fund)
- Category analysis (vs 3-month avg, daily pattern, verdict)
- Spend chart (monthly donut, per-category breakdown)
- Allocation recommendation (rule-based OR LLM-assisted; TBD)

### Phase 5 — Polish
- Goals tracking (shared + personal)
- Investments (manual positions)
- Recurring transactions (Cloud Function)
- Notifications (due date, budget warning)
- Export CSV/PDF
- Bank/e-wallet auto-import (large initiative; deferred)
- Flutter web build

## Open / Deferred Decisions
- Firestore schema (households embed vs subcollection; collection layout)
- State management pick (Riverpod default; confirm)
- Local DB for offline (drift vs isar; only if offline-first is needed)
- Multi-household per user (deferred; MVP = 1)
- Privacy within household (deferred; MVP = all visible)
- Health score formula (define when Phase 4 starts)
- Allocation engine: rules vs LLM (decide at Phase 4)

## Next Step
Sketch Firestore data model for Phase 0 + 1 before scaffolding code.
