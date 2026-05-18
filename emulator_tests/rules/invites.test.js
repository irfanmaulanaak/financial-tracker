import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { expect } from 'chai';
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
  accessLevel: 'limited',
  householdName: 'Keluarga A',
  inviterDisplayName: 'Alice',
  ...overrides,
});

// SEC-001 — invite codes are 128-bit URL-safe tokens (22 chars). Guessing is
// infeasible, so `allow get` is open to any authed caller — the token IS the
// credential. Tests use deterministic but token-shaped IDs.
const TOKEN_A = 'aaaaaaaaaaaaaaaaaaaa01';
const TOKEN_B = 'bbbbbbbbbbbbbbbbbbbb02';
const TOKEN_C = 'cccccccccccccccccccc03';
const TOKEN_D = 'dddddddddddddddddddd04';
const TOKEN_E = 'eeeeeeeeeeeeeeeeeeee05';
const TOKEN_F = 'ffffffffffffffffffff06';

describe('rules / invites/{code}', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('token holder reads preview fields (householdName, inviterDisplayName)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_A), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    const snap = await assertSucceeds(getDoc(doc(bobDb, 'invites', TOKEN_A)));
    expect(snap.data().householdName).to.equal('Keluarga A');
    expect(snap.data().inviterDisplayName).to.equal('Alice');
    expect(snap.data().accessLevel).to.equal('limited');
  });

  it('non-existent token returns not-found rather than denying enumeration', async () => {
    const bobDb = await dbAs('bob');
    const snap = await assertSucceeds(getDoc(doc(bobDb, 'invites/zzzzzzzzzzzzzzzzzzzz99')));
    expect(snap.exists()).to.equal(false);
  });

  it('anonymous cannot read', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_A), baseInvite('alice'));
    });
    const db = await dbAsAnon();
    await assertFails(getDoc(doc(db, 'invites', TOKEN_A)));
  });

  it('only generator can create with self as generatedBy', async () => {
    const aliceDb = await dbAs('alice');
    await assertSucceeds(
      setDoc(doc(aliceDb, 'invites', TOKEN_A), baseInvite('alice'))
    );
    await assertFails(
      setDoc(doc(aliceDb, 'invites', TOKEN_B), baseInvite('bob'))
    );
  });

  it('update allowed only as a single consume binding self as consumedBy', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_B), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertSucceeds(
      updateDoc(doc(bobDb, 'invites', TOKEN_B), {
        consumed: true,
        consumedBy: 'bob',
      })
    );
  });

  it('update denied when binding consumedBy to someone else', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_C), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'invites', TOKEN_C), {
        consumed: true,
        consumedBy: 'carol',
      })
    );
  });

  it('update denied when changing immutable fields (householdId, generatedBy, expiresAt)', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_D), baseInvite('alice'));
    });
    const bobDb = await dbAs('bob');
    await assertFails(
      updateDoc(doc(bobDb, 'invites', TOKEN_D), {
        consumed: true,
        consumedBy: 'bob',
        householdId: 'hijacked',
      })
    );
  });

  it('update denied once consumed', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(
        doc(db, 'invites', TOKEN_E),
        baseInvite('alice', { consumed: true, consumedBy: 'bob' })
      );
    });
    const eveDb = await dbAs('eve');
    await assertFails(
      updateDoc(doc(eveDb, 'invites', TOKEN_E), { consumed: true })
    );
  });

  it('only generator can delete', async () => {
    await seedWithoutRules(async (db) => {
      await setDoc(doc(db, 'invites', TOKEN_F), baseInvite('alice'));
    });
    const eveDb = await dbAs('eve');
    await assertFails(deleteDoc(doc(eveDb, 'invites', TOKEN_F)));
    const aliceDb = await dbAs('alice');
    await assertSucceeds(deleteDoc(doc(aliceDb, 'invites', TOKEN_F)));
  });
});
