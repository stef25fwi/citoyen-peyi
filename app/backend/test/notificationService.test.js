import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n';

const notifications = await import('../src/services/notificationService.js');

test('notificationSubscriptionDocId hashes FCM tokens deterministically', () => {
  const first = notifications.notificationSubscriptionDocId(' token-123 ');
  const second = notifications.notificationSubscriptionDocId('token-123');

  assert.equal(first, second);
  assert.match(first, /^[a-f0-9]{64}$/);
  assert.notEqual(first, 'token-123');
});

test('isPollVisibleForNotification respects status and dates', () => {
  const now = new Date('2026-05-29T12:00:00Z');
  const yesterday = '2026-05-28';
  const tomorrow = '2026-05-30';

  assert.equal(
    notifications.isPollVisibleForNotification({ status: 'active', openDate: yesterday, closeDate: tomorrow }, now),
    true,
  );
  assert.equal(
    notifications.isPollVisibleForNotification({ status: 'draft', openDate: yesterday, closeDate: tomorrow }, now),
    false,
  );
  assert.equal(
    notifications.isPollVisibleForNotification({ status: 'active', openDate: tomorrow, closeDate: tomorrow }, now),
    false,
  );
  assert.equal(
    notifications.isPollVisibleForNotification({
      status: 'scheduled',
      scheduledPublishDate: yesterday,
      openDate: yesterday,
      closeDate: tomorrow,
    }, now),
    true,
  );
});

test('buildNewPollNotification targets the vote route and poll id', () => {
  const message = notifications.buildNewPollNotification({
    id: 'poll-1',
    communeId: 'commune-1',
    projectTitle: 'Mobilites du bourg',
  });

  assert.equal(message.notification.title, 'Nouvelle consultation Citoyen Peyi');
  assert.match(message.notification.body, /Mobilites du bourg/);
  assert.equal(message.data.type, 'new_poll');
  assert.equal(message.data.pollId, 'poll-1');
  assert.equal(message.data.route, '/access-citizen');
  assert.equal(message.webpush.notification.tag, 'poll-poll-1');
});