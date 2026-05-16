/**
 * Card + installment transactional flows: CC expense bump, cicilan creation,
 * pay-minimum, pay-full, installment progression.
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

function buildHousehold(creator) {
  return {
    name: 'Keluarga A',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: 0,
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
      { id: 'cc', label: 'Kartu Kredit', type: 'credit', builtIn: true },
    ],
    cashAccounts: [],
    savingsAccounts: [],
    schemaVersion: 1,
  };
}

const baseCard = (overrides = {}) => ({
  ownerId: 'alice',
  label: 'BCA Visa',
  last4: '1234',
  limit: 10000000,
  used: 0,
  dueDay: 25,
  apr: 0.18,
  accent: '#3B82F6',
  minPaymentPct: 0.10,
  ...overrides,
});

/** Mirrors ExpenseRepository.addCardExpense. */
async function addCardExpense(db, hid, { cardId, amount, spentBy }) {
  const expenseRef = doc(collection(db, 'households', hid, 'expenses'));
  const cardRef = doc(db, 'households', hid, 'cards', cardId);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(cardRef);
    if (!snap.exists()) throw new Error('card_missing');
    const used = snap.data().used || 0;
    tx.set(expenseRef, {
      amount,
      categoryId: 'food',
      paymentMethodId: 'cc',
      spentBy,
      date: new Date(),
      recurring: false,
      cardId,
      createdAt: new Date(),
      createdBy: spentBy,
    });
    tx.update(cardRef, { used: used + amount });
  });
  return expenseRef.id;
}

/**
 * Mirrors ExpenseRepository.addCicilanExpense — using flat-rate cicilan.
 * Returns { expenseId, installmentId, total }.
 */
async function addCicilanExpense(db, hid, { cardId, principal, months, apr, spentBy }) {
  const monthlyInterest = apr / 12;
  const totalInterest = Math.round(principal * monthlyInterest * months);
  const total = principal + totalInterest;
  const monthly = Math.round(total / months);

  const expenseRef = doc(collection(db, 'households', hid, 'expenses'));
  const cardRef = doc(db, 'households', hid, 'cards', cardId);
  const installmentRef =
    doc(collection(db, 'households', hid, 'cards', cardId, 'installments'));

  await runTransaction(db, async (tx) => {
    const snap = await tx.get(cardRef);
    if (!snap.exists()) throw new Error('card_missing');
    const used = snap.data().used || 0;
    tx.set(expenseRef, {
      amount: principal,
      categoryId: 'food',
      paymentMethodId: 'cc',
      spentBy,
      date: new Date(),
      recurring: false,
      cardId,
      installmentPlanId: installmentRef.id,
      createdAt: new Date(),
      createdBy: spentBy,
    });
    tx.set(installmentRef, {
      expenseId: expenseRef.id,
      label: `Cicilan ${months}x`,
      total,
      monthly,
      monthsTotal: months,
      monthsPaid: 0,
      startedAt: new Date(),
    });
    tx.update(cardRef, { used: used + total });
  });

  return { expenseId: expenseRef.id, installmentId: installmentRef.id, total, monthly };
}

/** Mirrors CardRepository.payMinimum. */
async function payMinimum(db, hid, cardId, floor = 50000) {
  const cardRef = doc(db, 'households', hid, 'cards', cardId);
  return runTransaction(db, async (tx) => {
    const snap = await tx.get(cardRef);
    const data = snap.data();
    const balance = data.used || 0;
    if (balance <= 0) return 0;
    const pct = Math.round(balance * (data.minPaymentPct || 0.10));
    const raw = pct < floor ? floor : pct;
    const amount = raw > balance ? balance : raw;
    tx.update(cardRef, { used: balance - amount });
    return amount;
  });
}

/** Mirrors CardRepository.payFull. */
async function payFull(db, hid, cardId) {
  const cardRef = doc(db, 'households', hid, 'cards', cardId);
  return runTransaction(db, async (tx) => {
    const snap = await tx.get(cardRef);
    const balance = snap.data().used || 0;
    tx.update(cardRef, { used: 0 });
    return balance;
  });
}

describe('flows / card CRUD + rules', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member can create a card', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await assertSucceeds(
      setDoc(doc(alice, 'households/h1/cards/c1'), baseCard())
    );
  });

  it('non-member denied from creating a card', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    const eve = await dbAs('eve');
    await assertFails(
      setDoc(doc(eve, 'households/h1/cards/c1'), baseCard({ ownerId: 'eve' }))
    );
  });
});

describe('flows / CC expense bumps card.used', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('expense writes + card.used += amount atomically', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(doc(db, 'households/h1/cards/c1'), baseCard());
    });
    await addCardExpense(alice, 'h1', { cardId: 'c1', amount: 250000, spentBy: 'alice' });
    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(250000);

    await addCardExpense(alice, 'h1', { cardId: 'c1', amount: 100000, spentBy: 'alice' });
    const card2 = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card2.data().used).to.equal(350000);
  });

  it('rejects expense for non-existent card', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    let err;
    try {
      await addCardExpense(alice, 'h1', { cardId: 'ghost', amount: 1, spentBy: 'alice' });
    } catch (e) { err = e; }
    expect(err?.message).to.equal('card_missing');
  });
});

describe('flows / cicilan (Phase 3)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('0% APR cicilan: total = principal, monthly = principal / months', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(doc(db, 'households/h1/cards/c1'), baseCard());
    });
    const r = await addCicilanExpense(alice, 'h1', {
      cardId: 'c1', principal: 6000000, months: 6, apr: 0, spentBy: 'alice',
    });
    expect(r.total).to.equal(6000000);
    expect(r.monthly).to.equal(1000000);

    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(6000000);

    const inst = await getDoc(
      doc(alice, 'households/h1/cards/c1/installments', r.installmentId)
    );
    expect(inst.data().total).to.equal(6000000);
    expect(inst.data().monthsTotal).to.equal(6);
    expect(inst.data().monthsPaid).to.equal(0);
  });

  it('flat-rate cicilan: card.used reflects principal + interest', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(doc(db, 'households/h1/cards/c1'), baseCard());
    });
    // 18% APR flat over 12 months: interest = principal * 0.015 * 12 = 18%
    const r = await addCicilanExpense(alice, 'h1', {
      cardId: 'c1', principal: 10000000, months: 12, apr: 0.18, spentBy: 'alice',
    });
    expect(r.total).to.equal(11800000);
    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(11800000);
  });

  it('installment doc lives in cards/{cardId}/installments subcollection', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(doc(db, 'households/h1/cards/c1'), baseCard());
    });
    await addCicilanExpense(alice, 'h1', {
      cardId: 'c1', principal: 3000000, months: 3, apr: 0, spentBy: 'alice',
    });
    const list = await getDocs(
      collection(alice, 'households/h1/cards/c1/installments')
    );
    expect(list.size).to.equal(1);
  });
});

describe('flows / card payments', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('payMinimum reduces card.used by minimum (with floor)', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(
        doc(db, 'households/h1/cards/c1'),
        baseCard({ used: 1000000, minPaymentPct: 0.10 })
      );
    });
    const paid = await payMinimum(alice, 'h1', 'c1');
    expect(paid).to.equal(100000); // 10% > 50k floor
    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(900000);
  });

  it('payMinimum applies floor when percentage is below it', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(
        doc(db, 'households/h1/cards/c1'),
        baseCard({ used: 200000, minPaymentPct: 0.10 })
      );
    });
    const paid = await payMinimum(alice, 'h1', 'c1');
    expect(paid).to.equal(50000); // floor; 10% would be 20k
    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(150000);
  });

  it('payFull zeros card.used and returns previous balance', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(
        doc(db, 'households/h1/cards/c1'),
        baseCard({ used: 3500000 })
      );
    });
    const paid = await payFull(alice, 'h1', 'c1');
    expect(paid).to.equal(3500000);
    const card = await getDoc(doc(alice, 'households/h1/cards/c1'));
    expect(card.data().used).to.equal(0);
  });

  it('installment monthsPaid increment', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await setDoc(doc(db, 'households/h1/cards/c1'), baseCard());
    });
    const r = await addCicilanExpense(alice, 'h1', {
      cardId: 'c1', principal: 3000000, months: 3, apr: 0, spentBy: 'alice',
    });
    // bump monthsPaid via direct update (mirrors CardRepository.incrementInstallment)
    const instRef =
      doc(alice, 'households/h1/cards/c1/installments', r.installmentId);
    await runTransaction(alice, async (tx) => {
      const snap = await tx.get(instRef);
      tx.update(instRef, { monthsPaid: (snap.data().monthsPaid || 0) + 1 });
    });
    const after = await getDoc(instRef);
    expect(after.data().monthsPaid).to.equal(1);
  });
});
