/**
 * Accounts + income transactional flows. Accounts live as embedded arrays
 * (`cashAccounts`, `savingsAccounts`) on the household doc.
 */
import { assertSucceeds } from '@firebase/rules-unit-testing';
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

function buildHousehold(creator, opts = {}) {
  return {
    name: 'Keluarga A',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: 9000000,
    memberIds: [creator],
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
    categories: [
      { id: 'food', label: 'Food', icon: 'restaurant', color: '#F59E0B',
        monthlyBudget: 0, archived: false, sortOrder: 0 },
    ],
    paymentMethods: [
      { id: 'cash', label: 'Tunai', type: 'cash', builtIn: true },
      { id: 'cc', label: 'Kartu Kredit', type: 'credit', builtIn: true },
    ],
    cashAccounts: [],
    savingsAccounts: [],
    schemaVersion: 1,
    ...opts,
  };
}

/** Mirrors AccountsRepository.add (cash). */
async function addCashAccount(db, hid, { id, label, value = 0 }) {
  const ref = doc(db, 'households', hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    const cur = snap.data().cashAccounts || [];
    tx.update(ref, {
      cashAccounts: [...cur, { id, label, value, sortOrder: cur.length }],
    });
  });
}

/** Mirrors AccountsRepository.applyDelta. */
async function applyDelta(db, hid, accountId, delta) {
  const ref = doc(db, 'households', hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    const list = snap.data().cashAccounts || [];
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
  const houseRef = doc(db, 'households', hid);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(houseRef);
    const cash = snap.data().cashAccounts || [];
    const savings = snap.data().savingsAccounts || [];
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
    tx.update(houseRef, {
      [isCash ? 'cashAccounts' : 'savingsAccounts']: updated,
    });
  });
  return incomeRef.id;
}

describe('flows / accounts (embedded)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member can add a cash account', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await assertSucceeds(addCashAccount(alice, 'h1', { id: 'a1', label: 'Dompet', value: 500000 }));
    const snap = await getDoc(doc(alice, 'households/h1'));
    expect(snap.data().cashAccounts).to.have.lengthOf(1);
    expect(snap.data().cashAccounts[0].value).to.equal(500000);
  });

  it('applyDelta increases + clamps at zero', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [{ id: 'a1', label: 'Dompet', value: 100000, sortOrder: 0 }],
      }));
    });
    await applyDelta(alice, 'h1', 'a1', 50000);
    let snap = await getDoc(doc(alice, 'households/h1'));
    expect(snap.data().cashAccounts[0].value).to.equal(150000);

    await applyDelta(alice, 'h1', 'a1', -1000000); // huge negative
    snap = await getDoc(doc(alice, 'households/h1'));
    expect(snap.data().cashAccounts[0].value).to.equal(0); // clamped
  });
});

describe('flows / income (transaction bumps destination)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('income writes doc AND bumps destination cash account atomically', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [{ id: 'bca', label: 'BCA', value: 1000000, sortOrder: 0 }],
      }));
    });
    await addIncome(alice, 'h1', { amount: 5000000, destId: 'bca', receivedBy: 'alice' });

    const hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().cashAccounts[0].value).to.equal(6000000);

    const list = await getDocs(collection(alice, 'households/h1/incomes'));
    expect(list.size).to.equal(1);
    expect(list.docs[0].data().amount).to.equal(5000000);
    expect(list.docs[0].data().destinationAccountId).to.equal('bca');
  });

  it('income to savings account bumps savingsAccounts', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        savingsAccounts: [{ id: 'sv', label: 'Tabungan', value: 0, sortOrder: 0 }],
      }));
    });
    await addIncome(alice, 'h1', { amount: 2000000, destId: 'sv', receivedBy: 'alice' });
    const hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().savingsAccounts[0].value).to.equal(2000000);
  });

  it('rejects income to unknown account', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    let err;
    try {
      await addIncome(alice, 'h1', { amount: 100, destId: 'ghost', receivedBy: 'alice' });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('account_missing');
  });
});
