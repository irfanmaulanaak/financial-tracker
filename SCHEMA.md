# Firestore Schema

Sharing model: 1 user ↔ 1 household. All shared data nested under the household. Per-user profile separate.

## Collections

### `users/{uid}` — top-level, per authenticated user
```
email: string
displayName: string
photoURL: string?
householdId: string?      // null until joined/created
createdAt: timestamp
```

### `households/{hid}` — top-level
```
name: string
creatorId: uid
createdAt: timestamp

// Cycle config
payday: number             // 1-31, default 30 (weekend rollback applied at read time)
currency: 'IDR'            // locked
locale: 'id-ID'            // locked
monthlyBudgetTotal: number // IDR

// Security rules — must mirror members[].userId so rules can use `in`
memberIds: uid[]

// Fast-lookup mirror of members[].accessLevel keyed by uid. Kept in sync on
// every write that touches `members`; used by Firestore rules to resolve
// the caller's tier without iterating the array.
memberAccess: { <uid>: 'full' | 'limited' | 'view' }

// Embedded (bounded sets)
members: [{
  userId: uid
  displayName: string
  role: 'Suami'|'Istri'|'Anak'|'Orang Tua'|'Lainnya'  // label only
  color: string
  joinedAt: timestamp
  isCreator: boolean
  // Permission tier (the source of truth):
  // - 'full'    → all writes (settings, members, txn, cards, goals, invest)
  // - 'limited' → expenses + incomes only
  // - 'view'    → no writes; reads only
  accessLevel: 'full' | 'limited' | 'view'
}]

categories: [{
  id: string                // short slug, e.g. 'food'
  label: string
  icon: string
  color: string
  monthlyBudget: number
  archived: boolean
  sortOrder: number
}]

paymentMethods: [{
  id: string
  label: string             // 'Tunai', 'BCA Debit', 'GoPay', ...
  type: 'cash'|'debit'|'ewallet'|'credit'
  builtIn: boolean
}]

cashAccounts: [{ id, label, hint, value, sortOrder }]
savingsAccounts: [{ id, label, hint, value, interestRate?, maturity?, sortOrder }]
```

### `households/{hid}/expenses/{eid}` — subcollection
```
amount: number
categoryId: string
paymentMethodId: string
note: string?
spentBy: uid
date: timestamp           // user-selected; backdate allowed
recurring: boolean        // metadata only Phase 1-3
cardId: string?           // if paid via CC
installmentPlanId: string?
createdAt: timestamp
createdBy: uid
```

### `households/{hid}/incomes/{iid}` — subcollection
```
amount: number
sourceId: string          // 'salary'|'freelance'|'invest'|'gift'|'refund'|'other'
destinationAccountId: string   // → cashAccounts[].id
note: string?
receivedBy: uid
date: timestamp
recurring: boolean
createdAt: timestamp
createdBy: uid
```

### `households/{hid}/cards/{cardId}` — subcollection (per-member owned)
```
ownerId: uid
label: string
last4: string
limit: number
used: number              // mirror; recomputed from expenses
dueDay: number            // 1-31
apr: number
accent: string
minPaymentPct: number     // e.g. 0.10
```

### `households/{hid}/cards/{cardId}/installments/{instId}` — sub-sub
```
expenseId: string         // back-ref to originating expense
label: string
total: number             // principal + interest over plan
monthly: number
monthsTotal: number
monthsPaid: number
startedAt: timestamp
```

### `households/{hid}/goals/{gid}` — subcollection
```
label: string
target: number
current: number
dueDate: timestamp
monthlyContrib: number
icon: string
color: string
scope: 'shared'|'personal'
ownerId: uid?             // null if shared
```

### `households/{hid}/investments/{invId}` — subcollection (Phase 5)
```
label, hint, value, delta, color
```

### `invites/{code}` — top-level, code as doc ID
6-digit numeric. Single-use. Regenerated per invite. The role and access
tier are baked at create time and applied at join time — joiners cannot
escalate.
```
householdId: string
generatedBy: uid
generatedAt: timestamp
expiresAt: timestamp      // 24h default
consumed: boolean
consumedBy: uid?
consumedAt: timestamp?
role: 'Suami'|'Istri'|'Anak'|'Orang Tua'|'Lainnya'
accessLevel: 'full'|'limited'|'view'
```

## Composite Indexes
- `expenses`: (date desc) — implicit
- `expenses`: (categoryId, date desc)
- `expenses`: (spentBy, date desc)
- `expenses`: (cardId, date desc)
- `incomes`: (date desc)
- `incomes`: (destinationAccountId, date desc)

## Security Rules
See `firestore.rules` for the canonical version. Summary:
- `users/{uid}` — owner-only.
- `households/{hid}`:
  - `get` open to any authed user (so a joiner can validate via invite).
  - `list` blocked for non-members.
  - `update` requires `memberAccess[<uid>] == 'full'`. Self-join branch
    requires a valid `claimedInvite`.
  - Subcollections: `expenses`/`incomes` writable by full + limited;
    `cards`/`goals`/`investments` writable by full only.
- `invites/{code}` — `get` open to authed users, `list` blocked.

## Notes
- `memberIds` is the source of truth for membership checks in rules.
  `memberAccess` is the source of truth for access-tier checks in rules.
  `members[]` carries display data. All three must be kept in sync
  (transactional write on join/leave/access-change).
- Embed for bounded sets (≤ ~50 items): members, categories, payment methods, cash/savings accounts.
- Subcollection for unbounded or per-record entities: expenses, incomes, cards, goals, investments.
- Schema versioning: `schemaVersion` on household doc; bump on breaking
  changes; client-side migration on read. Current = `2` (added
  `memberAccess` map and `members[].accessLevel`).
