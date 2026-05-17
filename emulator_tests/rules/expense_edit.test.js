/**
 * Expense edit transactional flows. Mirrors ExpenseRepository.update which
 * reverses old balance side-effects (account refund or card.used reduction)
 * and re-applies new ones in a single transaction.
 *
 * Covers the four lane combinations:
 *   cash -> cash (same / different account)
 *   cash -> credit
 *   credit -> cash
 *   credit -> credit (same / different card)
 * Plus cicilan lane-lock guard.
 */
import { assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  collection,
  doc,
  getDoc,
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
      { id: 'fun', label: 'Hiburan', icon: 'movie', color: '#EC4899',
        monthlyBudget: 0, archived: false, sortOrder: 1 },
    ],
    paymentMethods: [
      { id: 'cash', label: 'Tunai', type: 'cash', builtIn: true },
    ],
    cashAccounts: [],
    savingsAccounts: [],
    schemaVersion: 1,
    ...opts,
  };
}

/** Mirrors ExpenseRepository.add (cash lane). */
async function addCashExpense(db, hid, { amount, categoryId, spentBy, sourceAccountId }) {
  const expRef = doc(collection(db, 'households', hid, 'expenses'));
  const hRef = doc(db, 'households', hid);
  await runTransaction(db, async (tx) => {
    const hSnap = await tx.get(hRef);
    const cash = hSnap.data().cashAccounts || [];
    const savings = hSnap.data().savingsAccounts || [];
    const isCash = cash.some((a) => a.id === sourceAccountId);
    const isSavings = savings.some((a) => a.id === sourceAccountId);
    if (!isCash && !isSavings) throw new Error('account_missing');
    const list = isCash ? cash : savings;
    const updated = list.map((a) =>
      a.id === sourceAccountId ? { ...a, value: a.value - amount } : a
    );
    tx.set(expRef, {
      amount, categoryId, spentBy, sourceAccountId,
      date: new Date(), recurring: false,
      createdAt: new Date(), createdBy: spentBy,
    });
    tx.update(hRef, {
      [isCash ? 'cashAccounts' : 'savingsAccounts']: updated,
    });
  });
  return expRef.id;
}

/** Mirrors ExpenseRepository.addCardExpense. */
async function addCardExpense(db, hid, { amount, categoryId, spentBy, cardId }) {
  const expRef = doc(collection(db, 'households', hid, 'expenses'));
  const cardRef = doc(db, 'households', hid, 'cards', cardId);
  await runTransaction(db, async (tx) => {
    const cardSnap = await tx.get(cardRef);
    if (!cardSnap.exists()) throw new Error('card_missing');
    const card = cardSnap.data();
    tx.set(expRef, {
      amount, categoryId, spentBy, cardId,
      date: new Date(), recurring: false,
      createdAt: new Date(), createdBy: spentBy,
    });
    tx.update(cardRef, { used: card.used + amount });
  });
  return expRef.id;
}

/**
 * Mirrors ExpenseRepository.update — reverses old side-effect and applies new.
 * Cicilan rule: when the existing row has installmentPlanId set, throws
 * 'cicilan_edit_locked' if amount/card/source change.
 */
async function updateExpense(db, hid, expenseId, patch) {
  const expRef = doc(db, 'households', hid, 'expenses', expenseId);
  const hRef = doc(db, 'households', hid);

  await runTransaction(db, async (tx) => {
    const eSnap = await tx.get(expRef);
    if (!eSnap.exists()) throw new Error('expense_missing');
    const old = eSnap.data();
    const isCicilan = !!old.installmentPlanId;
    if (isCicilan) {
      const laneChanged =
        (patch.newCardId ?? null) !== (old.cardId ?? null) ||
        (patch.newSourceAccountId ?? null) !== (old.sourceAccountId ?? null) ||
        (patch.newAmount ?? old.amount) !== old.amount;
      if (laneChanged) throw new Error('cicilan_edit_locked');
    }

    const oldCardRef = old.cardId
      ? doc(db, 'households', hid, 'cards', old.cardId)
      : null;
    const newCardRef = patch.newCardId
      ? doc(db, 'households', hid, 'cards', patch.newCardId)
      : null;

    const hSnap = await tx.get(hRef);
    let cash = hSnap.data().cashAccounts || [];
    let savings = hSnap.data().savingsAccounts || [];

    const cardUsed = {};
    let oldCard;
    if (oldCardRef) {
      const s = await tx.get(oldCardRef);
      if (s.exists()) { oldCard = s.data(); cardUsed[old.cardId] = oldCard.used; }
    }
    let newCard;
    if (newCardRef && (!oldCardRef || newCardRef.path !== oldCardRef.path)) {
      const s = await tx.get(newCardRef);
      if (!s.exists()) throw new Error('card_missing');
      newCard = s.data();
      cardUsed[patch.newCardId] = newCard.used;
    }

    if (old.cardId && !isCicilan) {
      const cur = cardUsed[old.cardId] ?? 0;
      cardUsed[old.cardId] = Math.max(0, cur - old.amount);
    } else if (old.sourceAccountId) {
      const inCash = cash.some((a) => a.id === old.sourceAccountId);
      if (inCash) {
        cash = cash.map((a) =>
          a.id === old.sourceAccountId ? { ...a, value: a.value + old.amount } : a
        );
      } else {
        savings = savings.map((a) =>
          a.id === old.sourceAccountId ? { ...a, value: a.value + old.amount } : a
        );
      }
    }

    if (!isCicilan) {
      if (patch.newCardId) {
        const cur = cardUsed[patch.newCardId] ?? 0;
        cardUsed[patch.newCardId] = cur + patch.newAmount;
      } else if (patch.newSourceAccountId) {
        const inCash = cash.some((a) => a.id === patch.newSourceAccountId);
        const inSavings = savings.some((a) => a.id === patch.newSourceAccountId);
        if (!inCash && !inSavings) throw new Error('account_missing');
        if (inCash) {
          const src = cash.find((a) => a.id === patch.newSourceAccountId);
          if (src.value < patch.newAmount) throw new Error('insufficient');
          cash = cash.map((a) =>
            a.id === patch.newSourceAccountId ? { ...a, value: a.value - patch.newAmount } : a
          );
        } else {
          const src = savings.find((a) => a.id === patch.newSourceAccountId);
          if (src.value < patch.newAmount) throw new Error('insufficient');
          savings = savings.map((a) =>
            a.id === patch.newSourceAccountId ? { ...a, value: a.value - patch.newAmount } : a
          );
        }
      }
    }

    const updated = {
      ...old,
      amount: isCicilan ? old.amount : patch.newAmount,
      categoryId: patch.newCategoryId ?? old.categoryId,
      spentBy: patch.newSpentBy ?? old.spentBy,
      cardId: isCicilan ? old.cardId : (patch.newCardId ?? null),
      sourceAccountId: isCicilan ? old.sourceAccountId : (patch.newSourceAccountId ?? null),
    };
    // Strip nulls that Firestore would persist explicitly (mirror Expense.toMap).
    if (updated.cardId === null) delete updated.cardId;
    if (updated.sourceAccountId === null) delete updated.sourceAccountId;

    tx.set(expRef, updated);
    tx.update(hRef, {
      cashAccounts: cash,
      savingsAccounts: savings,
    });
    for (const [cid, used] of Object.entries(cardUsed)) {
      tx.update(doc(db, 'households', hid, 'cards', cid), { used });
    }
  });
}

async function seedCard(hid, cardId, used = 0, owner = 'alice') {
  await seedWithoutRules(async (db) => {
    await setDoc(doc(db, 'households', hid, 'cards', cardId), {
      label: cardId,
      limit: 10_000_000,
      used,
      dueDay: 15,
      apr: 0,
      owner,
      accent: '#000000',
      minPaymentPct: 10,
    });
  });
}

describe('expense edit / lane swap', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('cash A -> cash B refunds A and debits B exactly', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [
          { id: 'a', label: 'A', value: 1_000_000, sortOrder: 0 },
          { id: 'b', label: 'B', value: 1_000_000, sortOrder: 1 },
        ],
      }));
    });
    const id = await addCashExpense(alice, 'h1', {
      amount: 100_000, categoryId: 'food', spentBy: 'alice', sourceAccountId: 'a',
    });
    let hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().cashAccounts.find((a) => a.id === 'a').value).to.equal(900_000);

    await assertSucceeds(updateExpense(alice, 'h1', id, {
      newAmount: 100_000,
      newCategoryId: 'food',
      newSourceAccountId: 'b',
    }));
    hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().cashAccounts.find((a) => a.id === 'a').value).to.equal(1_000_000);
    expect(hSnap.data().cashAccounts.find((a) => a.id === 'b').value).to.equal(900_000);
  });

  it('cash -> credit refunds the account and bumps card.used', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [{ id: 'a', label: 'A', value: 1_000_000, sortOrder: 0 }],
      }));
    });
    await seedCard('h1', 'cc1', 0);
    const id = await addCashExpense(alice, 'h1', {
      amount: 200_000, categoryId: 'food', spentBy: 'alice', sourceAccountId: 'a',
    });

    await assertSucceeds(updateExpense(alice, 'h1', id, {
      newAmount: 200_000,
      newCategoryId: 'food',
      newCardId: 'cc1',
    }));

    const hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().cashAccounts[0].value).to.equal(1_000_000);
    const cardSnap = await getDoc(doc(alice, 'households/h1/cards/cc1'));
    expect(cardSnap.data().used).to.equal(200_000);
  });

  it('credit -> cash reverses card.used and debits the account', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [{ id: 'a', label: 'A', value: 500_000, sortOrder: 0 }],
      }));
    });
    await seedCard('h1', 'cc1', 0);
    const id = await addCardExpense(alice, 'h1', {
      amount: 300_000, categoryId: 'food', spentBy: 'alice', cardId: 'cc1',
    });

    await assertSucceeds(updateExpense(alice, 'h1', id, {
      newAmount: 300_000,
      newCategoryId: 'food',
      newSourceAccountId: 'a',
    }));

    const hSnap = await getDoc(doc(alice, 'households/h1'));
    expect(hSnap.data().cashAccounts[0].value).to.equal(200_000);
    const cardSnap = await getDoc(doc(alice, 'households/h1/cards/cc1'));
    expect(cardSnap.data().used).to.equal(0);
  });

  it('amount-only change on CC sets card.used = old - oldAmount + newAmount', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await seedCard('h1', 'cc1', 0);
    const id = await addCardExpense(alice, 'h1', {
      amount: 100_000, categoryId: 'food', spentBy: 'alice', cardId: 'cc1',
    });
    let cardSnap = await getDoc(doc(alice, 'households/h1/cards/cc1'));
    expect(cardSnap.data().used).to.equal(100_000);

    await assertSucceeds(updateExpense(alice, 'h1', id, {
      newAmount: 250_000,
      newCategoryId: 'food',
      newCardId: 'cc1',
    }));
    cardSnap = await getDoc(doc(alice, 'households/h1/cards/cc1'));
    expect(cardSnap.data().used).to.equal(250_000);
  });

  it('cicilan: lane swap rejected; category-only change succeeds', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice', {
        cashAccounts: [{ id: 'a', label: 'A', value: 1_000_000, sortOrder: 0 }],
      }));
    });
    await seedCard('h1', 'cc1', 600_000);
    // Hand-seed a cicilan expense (no transactional helper needed for setup).
    const expId = 'cicX';
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1/expenses', expId), {
        amount: 500_000,
        categoryId: 'fun',
        spentBy: 'alice',
        cardId: 'cc1',
        installmentPlanId: 'plan1',
        date: new Date(),
        recurring: false,
        createdAt: new Date(),
        createdBy: 'alice',
      });
    });

    let err;
    try {
      await updateExpense(alice, 'h1', expId, {
        newAmount: 500_000,
        newCategoryId: 'fun',
        newSourceAccountId: 'a', // lane swap -> should reject
      });
    } catch (e) { err = e; }
    expect(err?.message).to.equal('cicilan_edit_locked');

    // Category-only change: succeeds, financial state untouched.
    await assertSucceeds(updateExpense(alice, 'h1', expId, {
      newCategoryId: 'food',
    }));
    const after = await getDoc(doc(alice, 'households/h1/expenses', expId));
    expect(after.data().categoryId).to.equal('food');
    expect(after.data().cardId).to.equal('cc1');
    expect(after.data().installmentPlanId).to.equal('plan1');
    const cardSnap = await getDoc(doc(alice, 'households/h1/cards/cc1'));
    expect(cardSnap.data().used).to.equal(600_000); // unchanged
  });
});
