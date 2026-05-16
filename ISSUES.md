# Issues

Keep only active issues here. Remove an issue once it is fully addressed.

## Active

### Security: invite/self-join rules are too permissive
- `firestore.rules` lets any signed-in non-member add themselves to `memberIds` without proving a valid invite.
- `invites/{code}` update is allowed for any signed-in user while unconsumed.
- Fix with tighter rules/tests around invite consumption and household membership changes.

### Phase 5: recurring materialisation helper is not wired
- `lib/src/core/recurring.dart` has helper logic, but production code does not call it.
- Expenses/income only store `recurring: true`; no records are auto-created.

### Derived balances become stale after deletes
- Deleting credit-card expenses does not reverse `card.used`.
- Deleting cicilan expenses does not remove/reverse installment plans.
- Income delete already warns that destination account balance is not reversed; decide if that remains acceptable.

### Last-member leave does not delete all household data
- `HouseholdRepository.leave` deletes the household root doc only.
- Subcollections can remain orphaned when the last member leaves.

### Design mismatch with `claude-design`
- Home, assets/accounts, cards, goals, and insights now use the warm editorial cards, serif-led money hierarchy, compact sections, and floating bottom nav.
- Remaining: transaction entry, logs/details, investments/export/member/category screens still need the same treatment before this issue is closed.

### Auth sign-out silently swallows Google errors
- `AuthRepository.signOut` has an empty `catch`.
- Align with repo guidance: fail loud or surface expected best-effort behavior explicitly.
