import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  addDoc,
  runTransaction,
} from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import {
  clearData,
  dbAs,
  disposeAll,
  getTestEnv,
  seedWithoutRules,
} from './_setup.js';

const baseHousehold = (creatorUid, memberIds) => ({
  name: 'Keluarga A',
  creatorId: creatorUid,
  createdAt: new Date(),
  payday: 30,
  currency: 'IDR',
  locale: 'id-ID',
  monthlyBudgetTotal: 9000000,
  memberIds,
  members: memberIds.map((uid) => ({
    userId: uid,
    displayName: uid,
    role: 'Suami',
    color: '#B8825A',
    joinedAt: new Date(),
    isCreator: uid === creatorUid,
  })),
  categories: [],
  paymentMethods: [],
  schemaVersion: 1,
});

describe('rules / households/{hid}', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('creator can create when self is in memberIds', async () => {
    const db = await dbAs('alice');
    await assertSucceeds(
      setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']))
    );
  });

  it('rejects create when creatorId mismatches caller', async () => {
    const db = await dbAs('alice');
    await assertFails(
      setDoc(doc(db, 'households/h1'), baseHousehold('bob', ['bob']))
    );
  });

  it('rejects create when creator not in memberIds', async () => {
    const db = await dbAs('alice');
    await assertFails(
      setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['bob']))
    );
  });

  it('member can read', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice', 'bob']));
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(getDoc(doc(bobDb, 'households/h1')));
  });

  it('non-member (authed) can read root doc (relaxed for join flow)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
    });
    const eveDb = await dbAs('eve');
    await assertSucceeds(getDoc(doc(eveDb, 'households/h1')));
  });

  it('member can update', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice', 'bob']));
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(updateDoc(doc(bobDb, 'households/h1'), { name: 'New' }));
  });

  it('non-member cannot update', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
    });
    const eveDb = await dbAs('eve');
    await assertFails(updateDoc(doc(eveDb, 'households/h1'), { name: 'New' }));
  });

  it('member can write to subcollections (expenses)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
    });
    const aliceDb = await dbAs('alice');
    await assertSucceeds(
      addDoc(collection(aliceDb, 'households/h1/expenses'), {
        amount: 50000,
        categoryId: 'food',
        paymentMethodId: 'cash',
        spentBy: 'alice',
        date: new Date(),
        recurring: false,
        createdAt: new Date(),
        createdBy: 'alice',
      })
    );
  });

  // Helper: simulates the Dart join transaction (household update + invite consume).
  function joinTx(db, hid, code, joiner) {
    return runTransaction(db, async (tx) => {
      const hSnap = await tx.get(doc(db, 'households', hid));
      await tx.get(doc(db, 'invites', code));
      const ids = (hSnap.data()?.memberIds || []).concat(joiner);
      tx.update(doc(db, 'households', hid), {
        memberIds: ids,
        claimedInvite: code,
      });
      tx.update(doc(db, 'invites', code), {
        consumed: true,
        consumedBy: joiner,
        consumedAt: new Date(),
      });
    });
  }

  it('non-member self-join succeeds when invite is claimed + consumed in same tx', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
      await setDoc(doc(db, 'invites/111111'), {
        householdId: 'h1',
        generatedBy: 'alice',
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
        consumed: false,
      });
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(joinTx(bobDb, 'h1', '111111', 'bob'));
  });

  it('non-member self-join is denied without claimedInvite', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'households/h1'), { memberIds: ['alice', 'bob'] })
    );
  });

  it('non-member self-join is denied if invite is NOT consumed in same tx', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
      await setDoc(doc(db, 'invites/110000'), {
        householdId: 'h1',
        generatedBy: 'alice',
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
        consumed: false,
      });
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'households/h1'), {
        memberIds: ['alice', 'bob'],
        claimedInvite: '110000',
      })
    );
  });

  it('non-member self-join is denied when claimedInvite is consumed', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
      await setDoc(doc(db, 'invites/222222'), {
        householdId: 'h1',
        generatedBy: 'alice',
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
        consumed: true,
        consumedBy: 'carol',
      });
    });
    const bobDb = await dbAs('bob');
    await assertFails(joinTx(bobDb, 'h1', '222222', 'bob'));
  });

  it('non-member self-join is denied when claimedInvite targets a different household', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
      await setDoc(doc(db, 'invites/333333'), {
        householdId: 'other',
        generatedBy: 'alice',
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
        consumed: false,
      });
    });
    const bobDb = await dbAs('bob');
    await assertFails(joinTx(bobDb, 'h1', '333333', 'bob'));
  });

  it('non-member cannot add someone else to memberIds even with a valid invite', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
      await setDoc(doc(db, 'invites/444444'), {
        householdId: 'h1',
        generatedBy: 'alice',
        generatedAt: new Date(),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
        consumed: false,
      });
    });
    const bobDb = await dbAs('bob');
    await assertFails(joinTx(bobDb, 'h1', '444444', 'carol'));
  });

  it('non-member cannot write to subcollections', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'households/h1'), baseHousehold('alice', ['alice']));
    });
    const eveDb = await dbAs('eve');
    await assertFails(
      addDoc(collection(eveDb, 'households/h1/expenses'), {
        amount: 1,
        categoryId: 'food',
        paymentMethodId: 'cash',
        spentBy: 'eve',
        date: new Date(),
        recurring: false,
        createdAt: new Date(),
        createdBy: 'eve',
      })
    );
  });
});
