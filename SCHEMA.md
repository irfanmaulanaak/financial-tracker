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

// Embedded (bounded sets)
members: [{
  userId: uid
  displayName: string
  role: 'Istri'|'Suami'|'Anak'|'Other'  // label only
  color: string
  joinedAt: timestamp
  isCreator: boolean
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
6-digit numeric. Single-use. Regenerated per invite.
```
householdId: string
generatedBy: uid
generatedAt: timestamp
expiresAt: timestamp      // 24h default
consumed: boolean
consumedBy: uid?
consumedAt: timestamp?
```

## Composite Indexes
- `expenses`: (date desc) — implicit
- `expenses`: (categoryId, date desc)
- `expenses`: (spentBy, date desc)
- `expenses`: (cardId, date desc)
- `incomes`: (date desc)
- `incomes`: (destinationAccountId, date desc)

## Security Rules (sketch)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    match /households/{hid} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow create: if request.auth.uid == request.resource.data.creatorId
                    && request.auth.uid in request.resource.data.memberIds;
      allow update, delete: if request.auth.uid in resource.data.memberIds;

      match /{document=**} {
        allow read, write: if request.auth.uid in
          get(/databases/$(db)/documents/households/$(hid)).data.memberIds;
      }
    }

    match /invites/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null && !resource.data.consumed;
      allow delete: if request.auth.uid == resource.data.generatedBy;
    }
  }
}
```

## Notes
- `memberIds` is the source of truth for security rule evaluation; `members[]` carries display data. Both must be kept in sync (transactional write on join/leave).
- Embed for bounded sets (≤ ~50 items): members, categories, payment methods, cash/savings accounts.
- Subcollection for unbounded or per-record entities: expenses, incomes, cards, goals, investments.
- Phase 0 needs: `users`, `households` (creation + member join), `invites`. Everything else lands in later phases.
- Schema versioning: add `schemaVersion: 1` on household doc; bump on breaking changes; client-side migration on read.
