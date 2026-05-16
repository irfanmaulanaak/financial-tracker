/**
 * End-to-end transactional flows that mirror the Dart HouseholdRepository.
 * Verifies the *behavior* (not just rules): the same operations the Flutter
 * app performs, executed via JS SDK against the real Firestore emulator.
 */
import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
import {
  doc,
  collection,
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

const seededCategories = [
  { id: 'food', label: 'Makanan & Minuman', icon: 'restaurant', color: '#F59E0B', monthlyBudget: 0, archived: false, sortOrder: 0 },
  { id: 'bills', label: 'Tagihan & Utilitas', icon: 'receipt_long', color: '#3B82F6', monthlyBudget: 0, archived: false, sortOrder: 1 },
];

function buildHouseholdPayload({ creatorUid, name, payday, monthlyBudget }) {
  return {
    name,
    creatorId: creatorUid,
    createdAt: new Date(),
    payday,
    currency: 'IDR',
    locale: 'id-ID',
    monthlyBudgetTotal: monthlyBudget,
    memberIds: [creatorUid],
    members: [
      {
        userId: creatorUid,
        displayName: creatorUid,
        role: 'Suami',
        color: '#B8825A',
        joinedAt: new Date(),
        isCreator: true,
      },
    ],
    categories: seededCategories,
    paymentMethods: [
      { id: 'cash', label: 'Tunai', type: 'cash', builtIn: true },
    ],
    schemaVersion: 1,
  };
}

/** Mirrors HouseholdRepository.create. */
async function createHousehold(db, creatorUid, opts) {
  const hid = doc(collection(db, 'households')).id;
  await runTransaction(db, async (tx) => {
    const userRef = doc(db, 'users', creatorUid);
    const userSnap = await tx.get(userRef);
    if (userSnap.exists() && userSnap.data().householdId) {
      throw new Error('user_already_in_household');
    }
    tx.set(
      doc(db, 'households', hid),
      buildHouseholdPayload({ creatorUid, ...opts })
    );
    tx.set(userRef, { householdId: hid }, { merge: true });
  });
  return hid;
}

/** Mirrors HouseholdRepository.createInvite. */
async function createInvite(db, householdId, generatedBy) {
  const code = String(Math.floor(Math.random() * 1_000_000)).padStart(6, '0');
  await setDoc(doc(db, 'invites', code), {
    householdId,
    generatedBy,
    generatedAt: new Date(),
    expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
    consumed: false,
  });
  return code;
}

/** Mirrors HouseholdRepository.joinWithInvite. */
async function joinWithInvite(db, { code, userId, displayName }) {
  return runTransaction(db, async (tx) => {
    const inviteRef = doc(db, 'invites', code);
    const inviteSnap = await tx.get(inviteRef);
    if (!inviteSnap.exists()) throw new Error('invite_not_found');
    const inv = inviteSnap.data();
    if (inv.consumed) throw new Error('invite_consumed');
    if (new Date() > inv.expiresAt.toDate()) throw new Error('invite_expired');

    const householdRef = doc(db, 'households', inv.householdId);
    const hSnap = await tx.get(householdRef);
    if (!hSnap.exists()) throw new Error('household_missing');

    const userRef = doc(db, 'users', userId);
    const userSnap = await tx.get(userRef);
    if (userSnap.exists() && userSnap.data().householdId) {
      throw new Error('user_already_in_household');
    }

    const data = hSnap.data();
    if (data.memberIds.includes(userId)) throw new Error('already_member');

    const newMember = {
      userId,
      displayName,
      role: 'Istri',
      color: '#10B981',
      joinedAt: new Date(),
      isCreator: false,
    };
    tx.update(householdRef, {
      memberIds: [...data.memberIds, userId],
      members: [...data.members, newMember],
      claimedInvite: code,
    });
    tx.update(inviteRef, {
      consumed: true,
      consumedBy: userId,
      consumedAt: new Date(),
    });
    tx.set(userRef, { householdId: inv.householdId }, { merge: true });
    return inv.householdId;
  });
}

describe('flows / household lifecycle', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('creator creates household → user.householdId linked', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await assertSucceeds(
      createHousehold(aliceDb, 'alice', {
        name: 'Keluarga A',
        payday: 30,
        monthlyBudget: 9000000,
      })
    );

    const hSnap = await getDoc(doc(aliceDb, 'households', hid));
    expect(hSnap.exists()).to.equal(true);
    expect(hSnap.data().memberIds).to.deep.equal(['alice']);
    expect(hSnap.data().monthlyBudgetTotal).to.equal(9000000);

    const userSnap = await getDoc(doc(aliceDb, 'users/alice'));
    expect(userSnap.data().householdId).to.equal(hid);
  });

  it('refuses second household when user already in one', async () => {
    const aliceDb = await dbAs('alice');
    await createHousehold(aliceDb, 'alice', {
      name: 'First',
      payday: 30,
      monthlyBudget: 1,
    });
    let err;
    try {
      await createHousehold(aliceDb, 'alice', {
        name: 'Second',
        payday: 30,
        monthlyBudget: 1,
      });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('user_already_in_household');
  });
});

describe('flows / invite + join', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('happy path: alice invites → bob joins → invite consumed', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await createHousehold(aliceDb, 'alice', {
      name: 'Keluarga A',
      payday: 30,
      monthlyBudget: 9000000,
    });
    const code = await createInvite(aliceDb, hid, 'alice');

    const bobDb = await dbAs('bob');
    const joinedHid = await joinWithInvite(bobDb, {
      code,
      userId: 'bob',
      displayName: 'Bob',
    });
    expect(joinedHid).to.equal(hid);

    const hSnap = await getDoc(doc(bobDb, 'households', hid));
    expect(hSnap.data().memberIds).to.have.members(['alice', 'bob']);
    expect(hSnap.data().members).to.have.lengthOf(2);

    const inviteSnap = await getDoc(doc(bobDb, 'invites', code));
    expect(inviteSnap.data().consumed).to.equal(true);
    expect(inviteSnap.data().consumedBy).to.equal('bob');

    const bobUser = await getDoc(doc(bobDb, 'users/bob'));
    expect(bobUser.data().householdId).to.equal(hid);
  });

  it('rejects unknown code', async () => {
    const bobDb = await dbAs('bob');
    let err;
    try {
      await joinWithInvite(bobDb, {
        code: '999999',
        userId: 'bob',
        displayName: 'Bob',
      });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('invite_not_found');
  });

  it('rejects consumed code', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await createHousehold(aliceDb, 'alice', {
      name: 'A', payday: 30, monthlyBudget: 1,
    });
    const code = await createInvite(aliceDb, hid, 'alice');
    const bobDb = await dbAs('bob');
    await joinWithInvite(bobDb, {
      code, userId: 'bob', displayName: 'Bob',
    });
    const carolDb = await dbAs('carol');
    let err;
    try {
      await joinWithInvite(carolDb, {
        code, userId: 'carol', displayName: 'Carol',
      });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('invite_consumed');
  });

  it('rejects expired code', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await createHousehold(aliceDb, 'alice', {
      name: 'A', payday: 30, monthlyBudget: 1,
    });
    // Seed an expired invite directly (bypass rules).
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/000111'), {
        householdId: hid,
        generatedBy: 'alice',
        generatedAt: new Date(Date.now() - 48 * 3600 * 1000),
        expiresAt: new Date(Date.now() - 24 * 3600 * 1000),
        consumed: false,
      });
    });
    const bobDb = await dbAs('bob');
    let err;
    try {
      await joinWithInvite(bobDb, {
        code: '000111', userId: 'bob', displayName: 'Bob',
      });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('invite_expired');
  });

  it('rejects when joiner already in another household', async () => {
    const aliceDb = await dbAs('alice');
    const hid1 = await createHousehold(aliceDb, 'alice', {
      name: 'A1', payday: 30, monthlyBudget: 1,
    });
    const code1 = await createInvite(aliceDb, hid1, 'alice');
    const bobDb = await dbAs('bob');
    await joinWithInvite(bobDb, {
      code: code1, userId: 'bob', displayName: 'Bob',
    });
    // Now bob tries to join a second household.
    const carolDb = await dbAs('carol');
    const hid2 = await createHousehold(carolDb, 'carol', {
      name: 'A2', payday: 30, monthlyBudget: 1,
    });
    const code2 = await createInvite(carolDb, hid2, 'carol');
    let err;
    try {
      await joinWithInvite(bobDb, {
        code: code2, userId: 'bob', displayName: 'Bob',
      });
    } catch (e) {
      err = e;
    }
    expect(err?.message).to.equal('user_already_in_household');
  });
});

describe('flows / expense subcollection', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('member can add + read expense', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await createHousehold(aliceDb, 'alice', {
      name: 'A', payday: 30, monthlyBudget: 9000000,
    });
    await assertSucceeds(
      setDoc(doc(aliceDb, 'households', hid, 'expenses', 'e1'), {
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
    const snap = await getDoc(doc(aliceDb, 'households', hid, 'expenses', 'e1'));
    expect(snap.data().amount).to.equal(50000);
  });

  it('non-member is denied', async () => {
    const aliceDb = await dbAs('alice');
    const hid = await createHousehold(aliceDb, 'alice', {
      name: 'A', payday: 30, monthlyBudget: 1,
    });
    const eveDb = await dbAs('eve');
    await assertFails(
      setDoc(doc(eveDb, 'households', hid, 'expenses', 'eve1'), {
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
