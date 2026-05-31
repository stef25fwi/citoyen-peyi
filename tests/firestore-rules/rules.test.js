import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, writeBatch } from 'firebase/firestore';

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

const supportTicketData = (overrides = {}) => ({
  ticketId: 'ticket-1',
  communeId: '97101',
  communeName: 'Les Abymes',
  createdByUserId: 'admin-1',
  createdByName: 'Admin commune',
  createdByEmail: 'admin@example.test',
  createdByRole: 'admin_communal',
  assignedToRole: 'super_admin',
  subject: 'Besoin aide consultation',
  category: 'Problème technique',
  priority: 'normale',
  status: 'ouvert',
  lastMessage: 'Bonjour, nous avons besoin d’aide.',
  lastMessageByRole: 'admin_communal',
  messagesCount: 1,
  unreadForSuperAdmin: true,
  unreadForAdmin: false,
  createdAt: new Date('2026-01-01T10:00:00Z'),
  updatedAt: new Date('2026-01-01T10:00:00Z'),
  closedAt: null,
  closedBy: null,
  ...overrides,
});

const supportMessageData = (overrides = {}) => ({
  messageId: 'message-1',
  ticketId: 'ticket-1',
  senderId: 'admin-1',
  senderName: 'Admin commune',
  senderEmail: 'admin@example.test',
  senderRole: 'admin_communal',
  message: 'Bonjour, nous avons besoin d’aide.',
  createdAt: new Date('2026-01-01T10:00:00Z'),
  isInternal: true,
  readBySuperAdmin: false,
  readByAdmin: true,
  ...overrides,
});

test('public can read polls', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'polls/poll-1'), { id: 'poll-1', status: 'active' });
  });
  await assertSucceeds(getDoc(doc(anonDb(), 'polls/poll-1')));
});

test('public results read poll aggregates, not anonymous vote collections', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'polls/poll-results'), {
      id: 'poll-results',
      status: 'active',
      options: [{ id: 'opt-1', votes: 3 }],
    });
    await setDoc(doc(ctx.firestore(), 'poll_ballots/ballot-1'), { optionId: 'opt-1' });
    await setDoc(doc(ctx.firestore(), 'poll_participations/poll-results_hash'), { participationHash: 'x' });
  });

  await assertSucceeds(getDoc(doc(anonDb(), 'polls/poll-results')));
  await assertFails(getDoc(doc(anonDb(), 'poll_ballots/ballot-1')));
  await assertFails(getDoc(doc(anonDb(), 'poll_participations/poll-results_hash')));
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

test('anonymous vote collections are fully closed', async () => {
  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertFails(getDoc(doc(superDb, 'poll_participations/poll-1_hash')));
  await assertFails(setDoc(doc(superDb, 'poll_participations/poll-1_hash'), { participationHash: 'x' }));
  await assertFails(getDoc(doc(superDb, 'poll_ballots/ballot-1')));
  await assertFails(setDoc(doc(superDb, 'poll_ballots/ballot-1'), { optionId: 'opt-1' }));
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

test('notification_subscriptions is fully backend-managed', async () => {
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true });
  await assertFails(getDoc(doc(adminDb, 'notification_subscriptions/token-1')));
  await assertFails(setDoc(doc(adminDb, 'notification_subscriptions/token-1'), {
    token: 'fcm-token',
    communeId: 'commune-1',
  }));
});

test('commune admin can create and read own support ticket with first message', async () => {
  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
  const batch = writeBatch(adminDb);
  batch.set(doc(adminDb, 'support_tickets/ticket-1'), supportTicketData());
  batch.set(doc(adminDb, 'support_tickets/ticket-1/messages/message-1'), supportMessageData());

  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(adminDb, 'support_tickets/ticket-1')));
  await assertSucceeds(getDoc(doc(adminDb, 'support_tickets/ticket-1/messages/message-1')));
});

test('commune admin cannot access another commune support ticket', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1/messages/message-1'), supportMessageData());
  });

  const otherAdminDb = userDb('admin-2', { role: 'commune_admin', admin: true, communeId: '97102' });
  await assertFails(getDoc(doc(otherAdminDb, 'support_tickets/ticket-1')));
  await assertFails(getDoc(doc(otherAdminDb, 'support_tickets/ticket-1/messages/message-1')));
  await assertFails(setDoc(doc(otherAdminDb, 'support_tickets/ticket-1/messages/message-2'), supportMessageData({
    messageId: 'message-2',
    senderId: 'admin-2',
  })));
});

test('support tickets are private from anonymous users', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
  });

  await assertFails(getDoc(doc(anonDb(), 'support_tickets/ticket-1')));
  await assertFails(setDoc(doc(anonDb(), 'support_tickets/ticket-2'), supportTicketData({ ticketId: 'ticket-2' })));
});

test('super admin can read all support tickets and update status', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
  });

  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  await assertSucceeds(getDoc(doc(superDb, 'support_tickets/ticket-1')));
  await assertSucceeds(updateDoc(doc(superDb, 'support_tickets/ticket-1'), {
    status: 'en_cours',
    updatedAt: new Date('2026-01-01T11:00:00Z'),
    unreadForSuperAdmin: false,
  }));
});

test('commune admin can reply to own support ticket', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
  });

  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
  const batch = writeBatch(adminDb);
  batch.set(doc(adminDb, 'support_tickets/ticket-1/messages/message-2'), supportMessageData({
    messageId: 'message-2',
    message: 'Merci, voici les détails complémentaires.',
    readBySuperAdmin: false,
    readByAdmin: true,
  }));
  batch.update(doc(adminDb, 'support_tickets/ticket-1'), {
    lastMessage: 'Merci, voici les détails complémentaires.',
    lastMessageByRole: 'admin_communal',
    messagesCount: 2,
    updatedAt: new Date('2026-01-01T11:00:00Z'),
    unreadForSuperAdmin: true,
    unreadForAdmin: false,
  });

  await assertSucceeds(batch.commit());
});

test('super admin can reply and move open support ticket to in progress', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
  });

  const superDb = userDb('super-1', { role: 'super_admin', super_admin: true });
  const batch = writeBatch(superDb);
  batch.set(doc(superDb, 'support_tickets/ticket-1/messages/message-2'), supportMessageData({
    messageId: 'message-2',
    senderId: 'super-1',
    senderName: 'Super admin',
    senderEmail: 'super@example.test',
    senderRole: 'super_admin',
    message: 'Nous prenons ce ticket en charge.',
    readBySuperAdmin: true,
    readByAdmin: false,
  }));
  batch.update(doc(superDb, 'support_tickets/ticket-1'), {
    status: 'en_cours',
    lastMessage: 'Nous prenons ce ticket en charge.',
    lastMessageByRole: 'super_admin',
    messagesCount: 2,
    updatedAt: new Date('2026-01-01T11:00:00Z'),
    unreadForSuperAdmin: false,
    unreadForAdmin: true,
  });

  await assertSucceeds(batch.commit());
});

test('commune admin cannot change support status or create super admin message', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'support_tickets/ticket-1'), supportTicketData());
  });

  const adminDb = userDb('admin-1', { role: 'commune_admin', admin: true, communeId: '97101' });
  await assertFails(updateDoc(doc(adminDb, 'support_tickets/ticket-1'), { status: 'ferme' }));
  await assertFails(setDoc(doc(adminDb, 'support_tickets/ticket-1/messages/message-2'), supportMessageData({
    messageId: 'message-2',
    senderRole: 'super_admin',
  })));
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
