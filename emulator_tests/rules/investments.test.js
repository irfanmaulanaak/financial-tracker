/**
 * Investments subcollection: pooled household positions, member-gated.
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  doc,
  collection,
  getDoc,
  getDocs,
  setDoc,
  addDoc,
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

function positionDoc({ label, type = 'reksadana', currentValue, costBasis }) {
  return {
    label,
    type,
    currentValue,
    costBasis,
    updatedAt: new Date(),
  };
}

describe('flows / investments', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member can add + read positions', async () => {
    const alice = await dbAs('alice');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
    });
    await assertSucceeds(
      addDoc(collection(alice, 'households/h1/investments'),
        positionDoc({
          label: 'BBCA',
          type: 'saham',
          currentValue: 1_500_000,
          costBasis: 1_200_000,
        })),
    );
    const list = await getDocs(collection(alice, 'households/h1/investments'));
    expect(list.size).to.equal(1);
    expect(list.docs[0].data().currentValue).to.equal(1_500_000);
  });

  it('member can update currentValue (mark-to-market)', async () => {
    const alice = await dbAs('alice');
    let id;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(collection(db, 'households/h1/investments'),
        positionDoc({ label: 'X', currentValue: 100, costBasis: 100 }));
      id = ref.id;
    });
    await updateDoc(doc(alice, 'households/h1/investments', id),
      { currentValue: 250, updatedAt: new Date() });
    const snap = await getDoc(doc(alice, 'households/h1/investments', id));
    expect(snap.data().currentValue).to.equal(250);
  });

  it('member can delete a position', async () => {
    const alice = await dbAs('alice');
    let id;
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      const ref = await addDoc(collection(db, 'households/h1/investments'),
        positionDoc({ label: 'X', currentValue: 100, costBasis: 100 }));
      id = ref.id;
    });
    await assertSucceeds(
      deleteDoc(doc(alice, 'households/h1/investments', id)),
    );
  });

  it('non-member is denied read AND write', async () => {
    const bob = await dbAs('bob');
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), buildHousehold('alice'));
      await addDoc(collection(db, 'households/h1/investments'),
        positionDoc({ label: 'X', currentValue: 100, costBasis: 100 }));
    });
    await assertFails(getDocs(collection(bob, 'households/h1/investments')));
    await assertFails(
      addDoc(collection(bob, 'households/h1/investments'),
        positionDoc({ label: 'Y', currentValue: 1, costBasis: 1 })),
    );
  });
});
