# Issues

Keep only active issues here. Remove an issue once it is fully addressed.

## Active

### 1. Creator cannot remove another member

- Spec: [PLAN.md](PLAN.md:60) says members can leave themselves and creator can remove other members.
- Current UI only calls `_leave(household.id, user.uid)` for the signed-in user at [member_list_screen.dart](lib/src/features/members/member_list_screen.dart:124); member rows have no remove action.
- Current repository method also writes `_users.doc(userId)` at [household_repository.dart](lib/src/features/household/household_repository.dart:249), which security rules only allow the target user to write.
- Impact: creator removal is effectively missing.
- Fix: add a creator-only remove flow that updates the household membership safely. Decide whether the removed user's `users/{uid}.householdId` cleanup is client-side on next sign-in or handled by a trusted backend/manual admin path.

### 2. Client-side recurring runner can duplicate rows across devices

- Current trigger runs on every home mount per device/session at [home_screen.dart](lib/src/features/home/home_screen.dart:49).
- Current runner reads latest recurring rows and then creates new expense/income docs with random IDs via [recurring_runner.dart](lib/src/core/recurring_runner.dart:59), [expense_repository.dart](lib/src/features/expenses/expense_repository.dart:59), and [income_repository.dart](lib/src/features/incomes/income_repository.dart:40).
- Impact: if two members open the app at the same time after a missed month, both clients can materialise the same recurring expense/income. Income duplicates also bump account balances twice.
- Fix: make materialised docs deterministic per template/date or guard creation in a transaction with a stable `recurringKey + date` document ID.

### 3. Firestore rules expose household roots and invite docs to any signed-in user

- Current rules allow any authenticated user to read every `households/{hid}` root doc at [firestore.rules](firestore.rules:22), and every invite at [firestore.rules](firestore.rules:75).
- The household root contains member names, budgets, cash/savings account balances, categories, and payment methods per [SCHEMA.md](SCHEMA.md:16).
- Impact: any signed-in account can list/read household root data and invite docs, even when they are not a household member.
- Fix: restrict reads to members where possible. If invite joining still needs public lookup, prefer `allow get` over `allow read/list`, keep invite data minimal, and avoid exposing financial fields to non-members.

### 4. Credit card delete is incomplete and unsafe

- Spec says credit cards are CRUD in [PLAN.md](PLAN.md:15).
- Current UI has add/edit/detail/pay flows but no delete call; `deleteCard` only exists in the repository at [card_repository.dart](lib/src/features/cards/card_repository.dart:94).
- The repository delete removes only the card parent doc. Firestore does not delete nested subcollections when a parent doc is deleted, and installments live under `cards/{cardId}/installments` per [SCHEMA.md](SCHEMA.md:103).
- Impact: card delete is not user-accessible, and wiring the existing method would orphan installment docs and hide card debt from net worth.
- Fix: either block deleting cards with non-zero `used` or active installments, or cascade installments intentionally before deleting the card.

### 5. Firestore index config is empty while recurring queries need compound indexes

- Current recurring runner queries `recurring == true` plus `date >= since` for expenses and incomes at [recurring_runner.dart](lib/src/core/recurring_runner.dart:63) and [recurring_runner.dart](lib/src/core/recurring_runner.dart:123).
- Current [firestore.indexes.json](firestore.indexes.json:1) has no indexes.
- SCHEMA already lists composite indexes for planned query patterns at [SCHEMA.md](SCHEMA.md:144), but the recurring `(recurring, date)` pair is missing from that list too.
- Impact: emulator tests pass, but production can fail on missing index when recurring materialisation runs.
- Fix: add required Firestore composite indexes for recurring expense/income queries and any SCHEMA-listed query that is actually used.

### 7. Record screens exceed AGENTS.md file-size guardrail

- [AGENTS.md](AGENTS.md:12) says: "Keep files <~400 LOC; split/refactor as needed."
- `record_expense_screen.dart` is 1,122 lines; `record_income_screen.dart` is 655 lines.
- Impact: hard to review, test, and maintain; increases likelihood of merge conflicts.
- Fix: extract shared widgets (keypad, amount display, blink cursor, meta row, submit dot) into a `lib/src/features/record_common/` module; split cicilan-specific UI into its own sheet/widget.

### 8. Keypad/display widgets duplicated across record_expense and record_income

- `_SubmitDot`, `_AmountDisplay`, `_BlinkCursor`, `_MetaRow`, and `_Keypad` are defined identically in both [record_expense_screen.dart](lib/src/features/expenses/record_expense_screen.dart) and [record_income_screen.dart](lib/src/features/incomes/record_income_screen.dart), with only minor colour/label deltas.
- Impact: violates DRY; any keypad bug or accessibility fix must be applied in two places.
- Fix: extract to `lib/src/features/record_common/` (or `lib/src/ui/`) as parameterised reusable widgets.

## Resolved

### 6. ~~Analyzer fails on existing UI helper lint~~

- **Status**: Fixed. `lib/src/ui/ft_motion.dart:141` now uses a single-underscore discard parameter (`_`) instead of `__`; `flutter analyze` exits clean.
- Verified: `flutter analyze` passes with "No issues found!" on current worktree.

(End of file - total 67 lines)
