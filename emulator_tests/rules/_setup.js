import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rulesPath = resolve(__dirname, '../../firestore.rules');

const PROJECT_ID = 'financial-tracker-test';
const HOST = '127.0.0.1';
const FIRESTORE_PORT = 8080;

let envPromise;

/** Returns a singleton test environment connected to the running emulator. */
export function getTestEnv() {
  envPromise ??= initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
      host: HOST,
      port: FIRESTORE_PORT,
    },
  });
  return envPromise;
}

/** Clears all Firestore data in the emulator (call between tests). */
export async function clearData() {
  const env = await getTestEnv();
  await env.clearFirestore();
}

/** Builds a Firestore client authed as `uid`. */
export async function dbAs(uid) {
  const env = await getTestEnv();
  return env.authenticatedContext(uid).firestore();
}

/** Unauthenticated client (anonymous). */
export async function dbAsAnon() {
  const env = await getTestEnv();
  return env.unauthenticatedContext().firestore();
}

/** Bypasses security rules for setup. */
export async function seedWithoutRules(fn) {
  const env = await getTestEnv();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

export async function disposeAll() {
  if (!envPromise) return;
  const env = await envPromise;
  await env.cleanup();
  envPromise = undefined;
}
