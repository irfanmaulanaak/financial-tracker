/**
 * Komentar & reaksi di pengeluaran.
 *
 * Comments subcollection (households/{hid}/expenses/{eid}/comments):
 *   - create: txn-capable member, authorId must be self, text 1..500 chars
 *   - update: never
 *   - delete: author, or full member (moderation)
 * Reactions: map `reactions.{uid}` on the expense doc — covered by the
 * expense write rule (full + limited).
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  addDoc,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
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
  // extraMembers: {uid: accessLevel}
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

const expenseDoc = {
  amount: 50_000,
  categoryId: 'food',
  spentBy: 'alice',
  date: new Date(),
  recurring: false,
  createdAt: new Date(),
  createdBy: 'alice',
};

async function seedExpense(hid, eid, household) {
  await seedWithoutRules(async (db) => {
    await setDoc(doc(db, 'households', hid), household);
    await setDoc(doc(db, 'households', hid, 'expenses', eid), expenseDoc);
  });
}

const comment = (authorId, text = 'Mahal amat 😅') => ({
  authorId,
  text,
  createdAt: new Date(),
});

describe('expense comments & reactions', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member (limited) can comment as self', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { bob: 'limited' }));
    const bob = await dbAs('bob');
    await assertSucceeds(
      addDoc(collection(bob, 'households/h1/expenses/e1/comments'),
        comment('bob')),
    );
    const list = await getDocs(
      collection(bob, 'households/h1/expenses/e1/comments'));
    expect(list.size).to.equal(1);
  });

  it('cannot forge authorId', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { bob: 'limited' }));
    const bob = await dbAs('bob');
    await assertFails(
      addDoc(collection(bob, 'households/h1/expenses/e1/comments'),
        comment('alice')),
    );
  });

  it('view tier can read but not comment', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { vera: 'view' }));
    const vera = await dbAs('vera');
    await assertSucceeds(
      getDocs(collection(vera, 'households/h1/expenses/e1/comments')),
    );
    await assertFails(
      addDoc(collection(vera, 'households/h1/expenses/e1/comments'),
        comment('vera')),
    );
  });

  it('non-member denied', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice'));
    const mallory = await dbAs('mallory');
    await assertFails(
      getDocs(collection(mallory, 'households/h1/expenses/e1/comments')),
    );
    await assertFails(
      addDoc(collection(mallory, 'households/h1/expenses/e1/comments'),
        comment('mallory')),
    );
  });

  it('empty or >500 char text rejected', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice'));
    const alice = await dbAs('alice');
    await assertFails(
      addDoc(collection(alice, 'households/h1/expenses/e1/comments'),
        comment('alice', '')),
    );
    await assertFails(
      addDoc(collection(alice, 'households/h1/expenses/e1/comments'),
        comment('alice', 'x'.repeat(501))),
    );
  });

  it('author can delete own comment; other limited member cannot', async () => {
    await seedExpense('h1', 'e1',
      buildHousehold('alice', { bob: 'limited', cika: 'limited' }));
    const bob = await dbAs('bob');
    const ref = await addDoc(
      collection(bob, 'households/h1/expenses/e1/comments'), comment('bob'));

    const cika = await dbAs('cika');
    await assertFails(
      deleteDoc(doc(cika, 'households/h1/expenses/e1/comments', ref.id)),
    );
    await assertSucceeds(
      deleteDoc(doc(bob, 'households/h1/expenses/e1/comments', ref.id)),
    );
  });

  it('full member can moderate-delete others\' comments', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { bob: 'limited' }));
    const bob = await dbAs('bob');
    const ref = await addDoc(
      collection(bob, 'households/h1/expenses/e1/comments'), comment('bob'));
    const alice = await dbAs('alice');
    await assertSucceeds(
      deleteDoc(doc(alice, 'households/h1/expenses/e1/comments', ref.id)),
    );
  });

  it('comments cannot be edited', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice'));
    const alice = await dbAs('alice');
    const ref = await addDoc(
      collection(alice, 'households/h1/expenses/e1/comments'),
      comment('alice'));
    await assertFails(
      updateDoc(doc(alice, 'households/h1/expenses/e1/comments', ref.id),
        { text: 'edited' }),
    );
  });

  it('limited member can react and unreact via reactions map', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { bob: 'limited' }));
    const bob = await dbAs('bob');
    const eRef = doc(bob, 'households/h1/expenses/e1');
    await assertSucceeds(updateDoc(eRef, { 'reactions.bob': '👍' }));
    let snap = await getDoc(eRef);
    expect(snap.data().reactions.bob).to.equal('👍');

    await assertSucceeds(
      updateDoc(eRef, { 'reactions.bob': deleteField() }),
    );
    snap = await getDoc(eRef);
    expect(snap.data().reactions?.bob).to.equal(undefined);
  });

  it('view tier cannot react', async () => {
    await seedExpense('h1', 'e1', buildHousehold('alice', { vera: 'view' }));
    const vera = await dbAs('vera');
    await assertFails(
      updateDoc(doc(vera, 'households/h1/expenses/e1'),
        { 'reactions.vera': '👍' }),
    );
  });
});
