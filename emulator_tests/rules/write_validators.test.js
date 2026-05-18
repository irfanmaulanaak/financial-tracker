/**
 * SEC-003 coverage: per-collection rule validators.
 *
 * Locks in the must-deny behaviour for write paths a malicious client could
 * try to abuse:
 *   - impersonated `createdBy` (someone other than `request.auth.uid`)
 *   - negative / non-numeric `amount`
 *   - `spentBy`/`receivedBy`/`transferredBy` set to a non-member uid
 *   - limited tier deleting another member's row
 *   - limited tier mutating `createdBy` on update
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  collection,
  doc,
  setDoc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import {
  clearData,
  dbAs,
  disposeAll,
  getTestEnv,
  seedWithoutRules,
} from './_setup.js';

function household(creator, others = []) {
  const memberIds = [creator, ...others];
  return {
    name: 'Keluarga A',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    monthlyBudgetTotal: 9000000,
    memberIds,
    members: memberIds.map((uid) => ({
      userId: uid,
      displayName: uid,
      role: 'Suami',
      color: '#B8825A',
      joinedAt: new Date(),
      isCreator: uid === creator,
      accessLevel: uid === creator ? 'full' : 'limited',
    })),
    memberAccess: Object.fromEntries(
      memberIds.map((uid) => [uid, uid === creator ? 'full' : 'limited']),
    ),
    categories: [],
    schemaVersion: 2,
  };
}

function expensePayload({ amount = 50000, spentBy = 'alice', createdBy = spentBy } = {}) {
  return {
    amount,
    categoryId: 'food',
    spentBy,
    date: new Date(),
    recurring: false,
    createdAt: new Date(),
    createdBy,
  };
}

describe('SEC-003 / write validators', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('expense create with valid shape succeeds', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertSucceeds(
      setDoc(doc(bob, 'households/h1/expenses/e1'), expensePayload({ spentBy: 'bob' })),
    );
  });

  it('expense create denied when createdBy impersonates another user', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/expenses/e2'), expensePayload({
        spentBy: 'bob',
        createdBy: 'alice',
      })),
    );
  });

  it('expense create denied for non-positive amount', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/expenses/e3'),
        expensePayload({ spentBy: 'bob', amount: 0 })),
    );
    await assertFails(
      setDoc(doc(bob, 'households/h1/expenses/e4'),
        expensePayload({ spentBy: 'bob', amount: -100 })),
    );
  });

  it('expense create denied when spentBy is not a household member', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/expenses/e5'),
        expensePayload({ spentBy: 'eve', createdBy: 'bob' })),
    );
  });

  it('expense update denied when changing createdBy', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
      await setDoc(doc(db, 'households/h1/expenses/e6'),
        expensePayload({ spentBy: 'bob', createdBy: 'bob' }));
    });
    const bob = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bob, 'households/h1/expenses/e6'), { createdBy: 'alice' }),
    );
  });

  it('limited tier cannot delete another member\'s expense', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
      await setDoc(doc(db, 'households/h1/expenses/e7'),
        expensePayload({ spentBy: 'alice', createdBy: 'alice' }));
    });
    const bob = await dbAs('bob');
    await assertFails(deleteDoc(doc(bob, 'households/h1/expenses/e7')));
  });

  it('limited tier can delete their own expense', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
      await setDoc(doc(db, 'households/h1/expenses/e8'),
        expensePayload({ spentBy: 'bob', createdBy: 'bob' }));
    });
    const bob = await dbAs('bob');
    await assertSucceeds(deleteDoc(doc(bob, 'households/h1/expenses/e8')));
  });

  it('full tier can delete any member\'s expense', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
      await setDoc(doc(db, 'households/h1/expenses/e9'),
        expensePayload({ spentBy: 'bob', createdBy: 'bob' }));
    });
    const alice = await dbAs('alice');
    await assertSucceeds(deleteDoc(doc(alice, 'households/h1/expenses/e9')));
  });

  it('income create denied when receivedBy is not a household member', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/incomes/i1'), {
        amount: 100000,
        sourceId: 'salary',
        destinationAccountId: 'cash1',
        receivedBy: 'eve',
        date: new Date(),
        recurring: false,
        createdAt: new Date(),
        createdBy: 'bob',
      }),
    );
  });

  it('transfer create denied for limited tier with mismatched createdBy', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/transfers/t1'), {
        amount: 100000,
        fee: 0,
        sourceAccountId: 'a',
        destinationAccountId: 'b',
        transferredBy: 'bob',
        date: new Date(),
        createdAt: new Date(),
        createdBy: 'alice',
      }),
    );
  });

  it('cards: limited tier write denied (full-only)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/cards/c1'), {
        ownerId: 'bob',
        label: 'Bank',
        last4: '0001',
        limit: 1000000,
        used: 0,
        dueDay: 25,
        apr: 0.18,
        accent: '#3B82F6',
        minPaymentPct: 0.10,
      }),
    );
  });

  it('netWorthSnapshots: doc id must match YYYY-MM-DD', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice'));
    });
    const alice = await dbAs('alice');
    await assertSucceeds(
      setDoc(doc(alice, 'households/h1/netWorthSnapshots/2026-05-18'), {
        cash: 1, savings: 2, debt: 3, investments: 4, computedAt: new Date(),
      }),
    );
    await assertFails(
      setDoc(doc(alice, 'households/h1/netWorthSnapshots/not-a-date'), {
        cash: 1, savings: 2, debt: 3, investments: 4, computedAt: new Date(),
      }),
    );
  });

  it('goals: limited tier denied from creating goal', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
    });
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(doc(bob, 'households/h1/goals/g1'), {
        label: 'Vacation',
        target: 5000000,
        current: 0,
        monthlyContrib: 0,
        icon: 'savings',
        color: '#10B981',
        scope: 'shared',
        createdAt: new Date(),
        autoDebit: false,
        autoDebitDay: 1,
      }),
    );
  });

  it('goals/contributions: byUid must equal auth.uid; amount must be positive', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), household('alice', ['bob']));
      await setDoc(doc(db, 'households/h1/goals/g2'), {
        label: 'Vacation', target: 5000000, current: 0,
        monthlyContrib: 0, icon: 'savings', color: '#10B981',
        scope: 'shared', createdAt: new Date(),
        autoDebit: false, autoDebitDay: 1,
      });
    });
    const bob = await dbAs('bob');
    const okPath = collection(bob, 'households/h1/goals/g2/contributions');
    await assertSucceeds(
      setDoc(doc(okPath, 'c1'), { amount: 100000, at: new Date(), byUid: 'bob', source: 'manual' }),
    );
    await assertFails(
      setDoc(doc(okPath, 'c2'), { amount: 100000, at: new Date(), byUid: 'alice', source: 'manual' }),
    );
    await assertFails(
      setDoc(doc(okPath, 'c3'), { amount: 0, at: new Date(), byUid: 'bob', source: 'manual' }),
    );
  });
});
