import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n';

const polls = await import('../src/routes/polls.js');

test('resolveInitialPublication keeps draft as the default mode', () => {
  assert.deepEqual(polls.resolveInitialPublication({}), {
    status: 'draft',
    scheduledPublishDate: '',
  });
});

test('resolveInitialPublication supports immediate publication', () => {
  assert.deepEqual(polls.resolveInitialPublication({ publicationMode: 'immediate' }), {
    status: 'active',
    scheduledPublishDate: '',
  });
});

test('resolveInitialPublication requires a valid scheduled publication date', () => {
  assert.deepEqual(polls.resolveInitialPublication({ publicationMode: 'scheduled' }), {
    error: 'Date de publication programmee invalide.',
  });
  assert.deepEqual(
    polls.resolveInitialPublication({ publicationMode: 'scheduled', scheduledPublishDate: '2026-06-15' }),
    { status: 'scheduled', scheduledPublishDate: '2026-06-15' },
  );
});

test('isScheduledPublicationDue compares date-only values', () => {
  assert.equal(
    polls.isScheduledPublicationDue(
      { status: 'scheduled', scheduledPublishDate: '2026-05-29' },
      new Date('2026-05-29T12:00:00Z'),
    ),
    true,
  );
  assert.equal(
    polls.isScheduledPublicationDue(
      { status: 'scheduled', scheduledPublishDate: '2026-05-30' },
      new Date('2026-05-29T12:00:00Z'),
    ),
    false,
  );
});
test('buildQuestions sanitizes questions, options and icons', () => {
  const questions = polls.buildQuestions([
    {
      title: '  Quels aménagements ?  ',
      multiple: true,
      options: [
        { label: 'Espaces verts et parcs', icon: 'Park!' },
        { label: 'Éclairage public', icon: 'lighting' },
        { label: '' },
      ],
    },
    { title: 'Sans assez d\'options', options: [{ label: 'Seule' }] },
    'pas un objet',
  ]);
  assert.equal(questions.length, 1);
  assert.equal(questions[0].title, 'Quels aménagements ?');
  assert.equal(questions[0].multiple, true);
  assert.equal(questions[0].options.length, 2);
  assert.equal(questions[0].options[0].icon, 'park');
  assert.match(questions[0].id, /^q-/);
});

test('buildQuestions preserves existing ids and votes on update', () => {
  const existing = [{
    id: 'q-keep',
    title: 'Old',
    options: [{ id: 'o-keep', label: 'Old A', votes: 7 }],
  }];
  const questions = polls.buildQuestions([
    { title: 'New title', options: [{ label: 'New A' }, { label: 'New B' }] },
  ], existing);
  assert.equal(questions[0].id, 'q-keep');
  assert.equal(questions[0].options[0].id, 'o-keep');
  assert.equal(questions[0].options[0].votes, 7);
});
