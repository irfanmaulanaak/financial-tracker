import { assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { after, afterEach, before, describe, it } from 'mocha';

import { clearData, dbAs, dbAsAnon, disposeAll, getTestEnv } from './_setup.js';

describe('rules / users/{uid}', () => {
  before(async () => getTestEnv());
  afterEach(async () => clearData());
  after(async () => disposeAll());

  it('owner can write + read own user doc', async () => {
    const db = await dbAs('alice');
    await assertSucceeds(
      setDoc(doc(db, 'users/alice'), { email: 'a@x.com', displayName: 'A' })
    );
    await assertSucceeds(getDoc(doc(db, 'users/alice')));
  });

  it('non-owner is denied read + write', async () => {
    const aliceDb = await dbAs('alice');
    await setDoc(doc(aliceDb, 'users/alice'), { email: 'a@x.com' });

    const bobDb = await dbAs('bob');
    await assertFails(getDoc(doc(bobDb, 'users/alice')));
    await assertFails(setDoc(doc(bobDb, 'users/alice'), { email: 'x' }));
  });

  it('anonymous (unauthenticated) is denied', async () => {
    const db = await dbAsAnon();
    await assertFails(getDoc(doc(db, 'users/alice')));
    await assertFails(setDoc(doc(db, 'users/alice'), { email: 'x' }));
  });
});
