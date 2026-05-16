import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import {
  clearData,
  dbAs,
  dbAsAnon,
  disposeAll,
  getTestEnv,
  seedWithoutRules,
} from './_setup.js';

const baseInvite = (generatedBy, overrides = {}) => ({
  householdId: 'h1',
  generatedBy,
  generatedAt: new Date(),
  expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
  consumed: false,
  ...overrides,
});

describe('rules / invites/{code}', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('any signed-in user can read', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/123456'), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(getDoc(doc(bobDb, 'invites/123456')));
  });

  it('anonymous cannot read', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/123456'), baseInvite('alice'));
    });
    const db = await dbAsAnon();
    await assertFails(getDoc(doc(db, 'invites/123456')));
  });

  it('only generator can create with self as generatedBy', async () => {
    const aliceDb = await dbAs('alice');
    await assertSucceeds(
      setDoc(doc(aliceDb, 'invites/111111'), baseInvite('alice'))
    );
    await assertFails(
      setDoc(doc(aliceDb, 'invites/222222'), baseInvite('bob'))
    );
  });

  it('update allowed only as a single consume binding self as consumedBy', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/333333'), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(
      updateDoc(doc(bobDb, 'invites/333333'), {
        consumed: true,
        consumedBy: 'bob',
      })
    );
  });

  it('update denied when binding consumedBy to someone else', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/333334'), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'invites/333334'), {
        consumed: true,
        consumedBy: 'carol',
      })
    );
  });

  it('update denied when changing immutable fields (householdId, generatedBy, expiresAt)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/333335'), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'invites/333335'), {
        consumed: true,
        consumedBy: 'bob',
        householdId: 'hijacked',
      })
    );
  });

  it('update denied once consumed', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(
        doc(db, 'invites/444444'),
        baseInvite('alice', { consumed: true, consumedBy: 'bob' })
      );
    });
    const eveDb = await dbAs('eve');
    await assertFails(
      updateDoc(doc(eveDb, 'invites/444444'), { consumed: true })
    );
  });

  it('only generator can delete', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites/555555'), baseInvite('alice'));
    });
    const eveDb = await dbAs('eve');
    await assertFails(deleteDoc(doc(eveDb, 'invites/555555')));
    const aliceDb = await dbAs('alice');
    await assertSucceeds(deleteDoc(doc(aliceDb, 'invites/555555')));
  });
});
