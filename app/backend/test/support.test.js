import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n';

const support = await import('../src/routes/support.js');
const notifications = await import('../src/services/notificationService.js');

const superAdmin = { uid: 'super:default', role: 'super_admin', super_admin: true, admin: true };
const adminA = { uid: 'admin:a', role: 'commune_admin', admin: true, communeId: '97101' };
const adminB = { uid: 'admin:b', role: 'commune_admin', admin: true, communeId: '97102' };
const controller = { uid: 'controller:x', role: 'controller', controller: true };

test('serializeTicket applies safe defaults for a freshly created ticket', () => {
  const ticket = support.serializeTicket({
    id: 'ticket-1',
    data: () => ({
      ticketId: 'ticket-1',
      communeId: '97101',
      subject: 'Probleme de vote',
      unreadForSuperAdmin: true,
    }),
  });

  assert.equal(ticket.ticketId, 'ticket-1');
  assert.equal(ticket.assignedToRole, 'super_admin');
  assert.equal(ticket.createdByRole, 'admin_communal');
  assert.equal(ticket.status, 'ouvert');
  assert.equal(ticket.priority, 'normale');
  assert.equal(ticket.unreadForSuperAdmin, true);
  assert.equal(ticket.unreadForAdmin, false);
});

test('serializeTicket coerces unread flags to booleans', () => {
  const ticket = support.serializeTicket({ id: 't', data: () => ({}) });
  assert.equal(ticket.unreadForSuperAdmin, false);
  assert.equal(ticket.unreadForAdmin, false);
});

test('canAccessTicket lets the super admin reach every commune ticket', () => {
  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97101' }), true);
  assert.equal(support.canAccessTicket(superAdmin, { communeId: '97102' }), true);
});

test('canAccessTicket restricts a commune admin to their own commune', () => {
  assert.equal(support.canAccessTicket(adminA, { communeId: '97101' }), true);
  assert.equal(support.canAccessTicket(adminA, { communeId: '97102' }), false);
  assert.equal(support.canAccessTicket(adminB, { communeId: '97102' }), true);
});

test('canAccessTicket denies a non-admin user', () => {
  assert.equal(support.canAccessTicket(controller, { communeId: '97101' }), false);
});

test('sortTickets surfaces urgent tickets first then most recent', () => {
  const sorted = support.sortTickets([
    { ticketId: 'normal-old', priority: 'normale', updatedAt: '2026-06-01T00:00:00.000Z' },
    { ticketId: 'urgent', priority: 'urgente', updatedAt: '2026-05-01T00:00:00.000Z' },
    { ticketId: 'normal-new', priority: 'normale', updatedAt: '2026-06-10T00:00:00.000Z' },
  ]);

  assert.deepEqual(sorted.map((t) => t.ticketId), ['urgent', 'normal-new', 'normal-old']);
});

test('statusMessage produces a human readable line per status', () => {
  assert.match(support.statusMessage('resolu'), /Résolu/);
  assert.match(support.statusMessage('ferme'), /clôturé/);
  assert.equal(support.statusMessage('inconnu'), 'Le statut du ticket a été mis à jour.');
});

test('buildNewTicketNotification routes the super admin to the support inbox', () => {
  const message = notifications.buildNewTicketNotification({
    ticketId: 'ticket-9',
    communeName: 'Les Abymes',
    subject: 'Code citoyen illisible',
    priority: 'normale',
  });

  assert.equal(message.data.type, 'new_support_ticket');
  assert.equal(message.data.ticketId, 'ticket-9');
  assert.equal(message.data.route, '/super-admin/support');
  assert.equal(message.webpush.notification.tag, 'ticket-ticket-9');
  assert.match(message.notification.body, /Les Abymes/);
  assert.match(message.notification.body, /Code citoyen illisible/);
  assert.equal(message.notification.title, 'Nouveau ticket assistance');
});

test('buildNewTicketNotification flags urgent tickets in the title', () => {
  const message = notifications.buildNewTicketNotification({
    ticketId: 'ticket-10',
    communeName: 'Le Gosier',
    subject: 'Vote bloque',
    priority: 'urgente',
  });

  assert.equal(message.notification.title, '[URGENT] Nouveau ticket assistance');
});

test('notificationSubscriptionDocId is stable for the super admin token store', () => {
  const id = notifications.notificationSubscriptionDocId('fcm-token-abc');
  assert.match(id, /^[a-f0-9]{64}$/);
  assert.equal(notifications.SUPER_ADMIN_SUBSCRIPTION_COLLECTION, 'super_admin_push_subscriptions');
});
