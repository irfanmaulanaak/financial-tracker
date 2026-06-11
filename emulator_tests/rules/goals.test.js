/**
 * Goals subcollection: shared + personal. Members of the household can
 * create/read/update/delete; non-members are denied via the household subcoll
 * rule.
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  doc,
  collection,
  getDoc,
  getDocs,
  runTransaction,
  setDoc,
  addDoc,
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

function buildHousehold(creator) {
  return {
    name: 'H',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: 1000000,
    memberIds: [creator],
    memberAccess: { [creator]: 'full' },
    members: [
      {
        userId: creator,
        displayName: creator,
        role: 'Suami',
        color: '#B8825A',
        joinedAt: new Date(),
        isCreator: true,
      },
    ],
    categories: [],
    paymentMethods: [],
    cashAccounts: [],
    savingsAccounts: [],
    schemaVersion: 1,
  };
}

function goalDoc(opts) {
  return {
    label: opts.label,
    target: opts.target,
    current: opts.current ?? 0,
    monthlyContrib: opts.monthlyContrib ?? 0,
    icon: 'savings',
    color: '#10B981',
    scope: opts.scope ?? 'shared',
    ...(opts.ownerId ? { ownerId: opts.ownerId } : {}),
    createdAt: new Date(),
  };
}

/** Mirrors GoalRepository.contribute transaction. */
async function contribute(db, hid, goalId, amount) {
  const ref = doc(db, 'households', hid, 'goals', goalId);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists()) throw new Error('goal_missing');
    const next = Math.min(snap.data().target, snap.data().current + amount);
    tx.update(ref, { current: next });
  });
}

describe('flows / goals', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member can add a shared goal', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await assertSucceeds(
      addDoc(collection(alice, 'households/h1/goals'),
        goalDoc({ label: 'Dana darurat', target: 60_000_000, scope: 'shared' }))
    );
    const list = await getDocs(collection(alice, 'households/h1/goals'));
    expect(list.size).to.equal(1);
    expect(list.docs[0].data().scope).to.equal('shared');
  });

  it('member can add a personal goal owned by themselves', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await assertSucceeds(
      addDoc(collection(alice, 'households/h1/goals'),
        goalDoc({
          label: 'Liburan Jepang',
          target: 30_000_000,
          scope: 'personal',
          ownerId: 'alice',
        })),
    );
  });

  it('non-member is denied read AND write on goals subcollection', async () => {
    const bob = await dbAs('bob');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await addDoc(collection(db, 'households/h1/goals'),
        goalDoc({ label: 'X', target: 1000 }));
    });
    await assertFails(getDocs(collection(bob, 'households/h1/goals')));
    await assertFails(
      addDoc(collection(bob, 'households/h1/goals'),
        goalDoc({ label: 'Y', target: 1000 })),
    );
  });

  it('contribute transaction clamps to target', async () => {
    const alice = await dbAs('alice');
    let goalId;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(collection(db, 'households/h1/goals'),
        goalDoc({ label: 'Vespa', target: 50_000_000, current: 49_000_000 }));
      goalId = ref.id;
    });
    await contribute(alice, 'h1', goalId, 10_000_000);
    const snap = await getDoc(doc(alice, 'households/h1/goals', goalId));
    expect(snap.data().current).to.equal(50_000_000); // clamped
  });

  it('member can delete a goal', async () => {
    const alice = await dbAs('alice');
    let goalId;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(collection(db, 'households/h1/goals'),
        goalDoc({ label: 'X', target: 1000 }));
      goalId = ref.id;
    });
    await assertSucceeds(
      deleteDoc(doc(alice, 'households/h1/goals', goalId)),
    );
  });
});
