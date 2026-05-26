import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-citoyen-peyi',
    firestore: {
      rules: fs.readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8088,
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  if (env) await env.cleanup();
});

const anonDb = () => env.unauthenticatedContext().firestore();
const userDb = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();

test('public can read polls', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'polls/poll-1'), { id: 'poll-1', status: 'active' });
  });
  await assertSucceeds(getDoc(doc(anonDb(), 'polls/poll-1')));
});

test('client cannot write polls (must go through backend)', async () => {
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
  await assertFails(setDoc(doc(adminDb, 'polls/poll-bad'), { id: 'poll-bad', status: 'draft' }));
});

test('citizen_access_codes is fully closed to clients', async () => {
  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertFails(setDoc(doc(superDb, 'citizen_access_codes/ABCD1234'), { accessCode: 'ABCD1234' }));
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'citizen_access_codes/ABCD1234'), { accessCode: 'ABCD1234' });
  });
  await assertFails(getDoc(doc(superDb, 'citizen_access_codes/ABCD1234')));
  await assertFails(getDoc(doc(anonDb(), 'citizen_access_codes/ABCD1234')));
});

test('poll_votes is fully closed', async () => {
  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertFails(getDoc(doc(superDb, 'poll_votes/some-vote')));
  await assertFails(setDoc(doc(superDb, 'poll_votes/some-vote'), { optionId: 'opt-1' }));
});

test('communeAdmins is fully closed to clients', async () => {
  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertFails(getDoc(doc(superDb, 'communeAdmins/admin-1')));
  await assertFails(setDoc(doc(superDb, 'communeAdmins/admin-1'), { label: 'x' }));
});

test('controleurCodes is fully closed to clients', async () => {
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
  await assertFails(getDoc(doc(adminDb, 'controleurCodes/CTRL-ABCD')));
  await assertFails(setDoc(doc(adminDb, 'controleurCodes/CTRL-ABCD'), { code: 'CTRL-ABCD' }));
});

test('public_news is publicly readable but client cannot write', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'public_news/n1'), { title: 'Hello', body: 'World' });
  });
  await assertSucceeds(getDoc(doc(anonDb(), 'public_news/n1')));
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
  await assertFails(setDoc(doc(adminDb, 'public_news/n2'), { title: 'x', body: 'y' }));
});

test('registrationCodes legacy collection is locked down', async () => {
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
  await assertFails(getDoc(doc(adminDb, 'registrationCodes/old')));
  await assertFails(setDoc(doc(adminDb, 'registrationCodes/old'), { code: 'old' }));
});

test('unknown collection is denied by the wildcard rule', async () => {
  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertFails(getDoc(doc(superDb, 'random_collection/x')));
  await assertFails(setDoc(doc(superDb, 'random_collection/x'), { foo: 'bar' }));
});
