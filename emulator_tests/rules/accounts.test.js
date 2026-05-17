/**
 * Accounts + income transactional flows. Accounts live at
 * `households/{hid}/private/balances` (SEC-004) — full-tier only.
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
} from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import {
  clearData,
  dbAs,
  disposeAll,
  getTestEnv,
  seedWithoutRules,
} from './_setup.js';

function buildHousehold(creator, members = []) {
  const memberIds = [creator, ...members.map((m) => m.uid)];
  return {
    name: 'Keluarga A',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: 9000000,
    memberIds,
    members: [
      {
        userId: creator,
        displayName: creator,
        role: 'Suami',
        color: '#B8825A',
        joinedAt: new Date(),
        isCreator: true,
        accessLevel: 'full',
      },
      ...members.map((m) => ({
        userId: m.uid,
        displayName: m.uid,
        role: 'Istri',
        color: '#10B981',
        joinedAt: new Date(),
        isCreator: false,
        accessLevel: m.access || 'limited',
      })),
    ],
    memberAccess: {
      [creator]: 'full',
      ...Object.fromEntries(members.map((m) => [m.uid, m.access || 'limited'])),
    },
    categories: [
      { id: 'food', label: 'Food', icon: 'restaurant', color: '#F59E0B',
        monthlyBudget: 0, archived: false, sortOrder: 0 },
    ],
    schemaVersion: 3,
  };
}

const balancesPath = (hid) => doc.bind(null, undefined); // placeholder
function balancesDoc(db, hid) {
  return doc(db, 'households', hid, 'private', 'balances');
}

async function seedBalances(hid, { cashAccounts = [], savingsAccounts = [] } = {}) {
  await seedWithoutRules(async (db) => {
    await setDoc(balancesDoc(db, hid), {
      cashAccounts,
      savingsAccounts,
      updatedAt: new Date(),
    });
  });
}

/** Mirrors AccountsRepository.add (cash). Full-tier only. */
async function addCashAccount(db, hid, { id, label, value = 0 }) {
  const ref = balancesDoc(db, hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    const cur = snap.data()?.cashAccounts || [];
    tx.update(ref, {
      cashAccounts: [...cur, { id, label, value, sortOrder: cur.length }],
    });
  });
}

/** Mirrors AccountsRepository.applyDelta. */
async function applyDelta(db, hid, accountId, delta) {
  const ref = balancesDoc(db, hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    const list = snap.data()?.cashAccounts || [];
    const updated = list.map((a) =>
      a.id === accountId
        ? { ...a, value: Math.max(0, a.value + delta) }
        : a
    );
    tx.update(ref, { cashAccounts: updated });
  });
}

/** Mirrors IncomeRepository.add — tx writes income + bumps account. */
async function addIncome(db, hid, { amount, destId, receivedBy }) {
  const incomeRef = doc(collection(db, 'households', hid, 'incomes'));
  const balRef = balancesDoc(db, hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(balRef);
    const cash = snap.data()?.cashAccounts || [];
    const savings = snap.data()?.savingsAccounts || [];
    const isCash = cash.some((a) => a.id === destId);
    const isSavings = savings.some((a) => a.id === destId);
    if (!isCash && !isSavings) throw new Error('account_missing');
    const list = isCash ? cash : savings;
    const updated = list.map((a) =>
      a.id === destId ? { ...a, value: a.value + amount } : a
    );
    tx.set(incomeRef, {
      amount,
      sourceId: 'salary',
      destinationAccountId: destId,
      receivedBy,
      date: new Date(),
      recurring: false,
      createdAt: new Date(),
      createdBy: receivedBy,
    });
    tx.update(balRef, {
      [isCash ? 'cashAccounts' : 'savingsAccounts']: updated,
    });
  });
  return incomeRef.id;
}

describe('flows / accounts (private/balances)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('full-tier member can add a cash account', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1');
    await assertSucceeds(addCashAccount(alice, 'h1', {
      id: 'a1', label: 'Dompet', value: 500000,
    }));
    const snap = await getDoc(balancesDoc(alice, 'h1'));
    expect(snap.data().cashAccounts).to.have.lengthOf(1);
    expect(snap.data().cashAccounts[0].value).to.equal(500000);
  });

  it('applyDelta increases + clamps at zero', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1', {
      cashAccounts: [{ id: 'a1', label: 'Dompet', value: 100000, sortOrder: 0 }],
    });
    await applyDelta(alice, 'h1', 'a1', 50000);
    let snap = await getDoc(balancesDoc(alice, 'h1'));
    expect(snap.data().cashAccounts[0].value).to.equal(150000);

    await applyDelta(alice, 'h1', 'a1', -1000000);
    snap = await getDoc(balancesDoc(alice, 'h1'));
    expect(snap.data().cashAccounts[0].value).to.equal(0);
  });
});

describe('SEC-004 / balances privacy', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('limited-tier member is denied read of balances doc', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'),
        buildHousehold('alice', [{ uid: 'bob', access: 'limited' }]));
    });
    await seedBalances('h1', {
      cashAccounts: [{ id: 'a1', label: 'Secret', value: 999999, sortOrder: 0 }],
    });
    const bob = await dbAs('bob');
    await assertFails(getDoc(balancesDoc(bob, 'h1')));
  });

  it('limited-tier member is denied write of balances doc', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'),
        buildHousehold('alice', [{ uid: 'bob', access: 'limited' }]));
    });
    await seedBalances('h1');
    const bob = await dbAs('bob');
    await assertFails(
      setDoc(balancesDoc(bob, 'h1'), {
        cashAccounts: [{ id: 'x', label: 'New', value: 1, sortOrder: 0 }],
        savingsAccounts: [],
        updatedAt: new Date(),
      }),
    );
  });

  it('non-member is denied read of balances doc', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1');
    const eve = await dbAs('eve');
    await assertFails(getDoc(balancesDoc(eve, 'h1')));
  });

  it('full-tier member can read and write balances doc', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1', {
      cashAccounts: [{ id: 'a1', label: 'Dompet', value: 100, sortOrder: 0 }],
    });
    const read = await assertSucceeds(getDoc(balancesDoc(alice, 'h1')));
    expect(read.data().cashAccounts[0].value).to.equal(100);
  });
});

describe('flows / income (transaction bumps destination)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('income writes doc AND bumps destination cash account atomically', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1', {
      cashAccounts: [{ id: 'bca', label: 'BCA', value: 1000000, sortOrder: 0 }],
    });
    await addIncome(alice, 'h1', { amount: 5000000, destId: 'bca', receivedBy: 'alice' });

    const balSnap = await getDoc(balancesDoc(alice, 'h1'));
    expect(balSnap.data().cashAccounts[0].value).to.equal(6000000);

    const list = await getDocs(collection(alice, 'households/h1/incomes'));
    expect(list.size).to.equal(1);
    expect(list.docs[0].data().amount).to.equal(5000000);
    expect(list.docs[0].data().destinationAccountId).to.equal('bca');
  });

  it('income to savings account bumps savingsAccounts', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1', {
      savingsAccounts: [{ id: 'sv', label: 'Tabungan', value: 0, sortOrder: 0 }],
    });
    await addIncome(alice, 'h1', { amount: 2000000, destId: 'sv', receivedBy: 'alice' });
    const balSnap = await getDoc(balancesDoc(alice, 'h1'));
    expect(balSnap.data().savingsAccounts[0].value).to.equal(2000000);
  });

  it('rejects income to unknown account', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedBalances('h1');
    let err;
    try {
      await addIncome(alice, 'h1', { amount: 100, destId: 'ghost', receivedBy: 'alice' });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('account_missing');
  });
});
