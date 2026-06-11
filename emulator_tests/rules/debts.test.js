/**
 * Utang/piutang ledger (households/{hid}/debts).
 * Write = full + limited (sama seperti expenses); view = read-only;
 * non-member denied.
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  runTransaction,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import {
  clearData,
  dbAs,
  disposeAll,
  getTestEnv,
  seedWithoutRules,
} from './_setup.js';

function buildHousehold(creator, extraMembers = {}) {
  const memberIds = [creator, ...Object.keys(extraMembers)];
  const memberAccess = { [creator]: 'full', ...extraMembers };
  return {
    name: 'H',
    creatorId: creator,
    createdAt: new Date(),
    payday: 30,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: 1000000,
    memberIds,
    memberAccess,
    members: memberIds.map((uid) => ({
      userId: uid,
      displayName: uid,
      role: 'Lainnya',
      color: '#B8825A',
      joinedAt: new Date(),
      isCreator: uid === creator,
      accessLevel: memberAccess[uid],
    })),
    categories: [],
    paymentMethods: [],
    cashAccounts: [],
    savingsAccounts: [],
    schemaVersion: 1,
  };
}

const debtDoc = (overrides = {}) => ({
  type: 'utang',
  counterparty: 'Pak Budi',
  amount: 1_000_000,
  paid: 0,
  settled: false,
  createdAt: new Date(),
  createdBy: 'alice',
  ...overrides,
});

/** Mirrors DebtRepository.addPayment (transactional clamp). */
async function addPayment(db, hid, debtId, payment) {
  const ref = doc(db, 'households', hid, 'debts', debtId);
  await runTransaction(db, async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists()) throw new Error('debt_missing');
    const { amount, paid } = snap.data();
    const next = Math.min(amount, Math.max(0, paid + payment));
    tx.update(ref, { paid: next, settled: next >= amount });
  });
}

describe('debts (utang/piutang)', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('limited member can create and read', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'),
        buildHousehold('alice', { bob: 'limited' }));
    });
    const bob = await dbAs('bob');
    await assertSucceeds(
      addDoc(collection(bob, 'households/h1/debts'),
        debtDoc({ createdBy: 'bob' })),
    );
    const list = await getDocs(collection(bob, 'households/h1/debts'));
    expect(list.size).to.equal(1);
  });

  it('payment transaction clamps and settles', async () => {
    let debtId;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(collection(db, 'households/h1/debts'),
        debtDoc({ amount: 500_000, paid: 400_000 }));
      debtId = ref.id;
    });
    const alice = await dbAs('alice');
    await assertSucceeds(addPayment(alice, 'h1', debtId, 999_999));
    const snap = await getDoc(doc(alice, 'households/h1/debts', debtId));
    expect(snap.data().paid).to.equal(500_000);
    expect(snap.data().settled).to.equal(true);
  });

  it('view tier reads but cannot write', async () => {
    let debtId;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'),
        buildHousehold('alice', { vera: 'view' }));
      const ref = await addDoc(
        collection(db, 'households/h1/debts'), debtDoc());
      debtId = ref.id;
    });
    const vera = await dbAs('vera');
    await assertSucceeds(getDocs(collection(vera, 'households/h1/debts')));
    await assertFails(
      addDoc(collection(vera, 'households/h1/debts'), debtDoc()),
    );
    await assertFails(
      updateDoc(doc(vera, 'households/h1/debts', debtId),
        { paid: 1_000_000 }),
    );
    await assertFails(
      deleteDoc(doc(vera, 'households/h1/debts', debtId)),
    );
  });

  it('non-member denied read and write', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await addDoc(collection(db, 'households/h1/debts'), debtDoc());
    });
    const mallory = await dbAs('mallory');
    await assertFails(getDocs(collection(mallory, 'households/h1/debts')));
    await assertFails(
      addDoc(collection(mallory, 'households/h1/debts'), debtDoc()),
    );
  });

  it('member can delete a debt note', async () => {
    let debtId;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(
        collection(db, 'households/h1/debts'), debtDoc());
      debtId = ref.id;
    });
    const alice = await dbAs('alice');
    await assertSucceeds(
      deleteDoc(doc(alice, 'households/h1/debts', debtId)),
    );
  });
});
