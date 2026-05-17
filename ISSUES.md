# Issues

Keep only active issues here. Remove an issue once it is fully addressed.

## Active

### 3. Firestore rules: household root + invite docs readable by any signed-in user (partial)

- Status: **Partially mitigated.** `list` is now blocked on both `households` and `invites`; `get` stays open so a joiner can validate an invite code before redeeming it ([firestore.rules](firestore.rules:39), [firestore.rules](firestore.rules:158)). No global enumeration is possible.
- Residual concern: a signed-in non-member who knows a `householdId` can still `get` the root doc (which exposes member names, budgets, account balances, categories).
- Decision: acceptable per AGENTS.md ("internal app, 2-5 known users"). Tightening would require either a Cloud Function for invite validation or splitting the household root into a public-stub + private-data pair. Out of scope for the current trust model.
- Re-open if: external/multi-tenant deployment is on the table.
