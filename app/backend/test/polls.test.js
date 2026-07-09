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

test('publicPollPayloadFrom projects multi-question surveys and hides internal-only fields', () => {
  const poll = {
    id: 'poll-survey',
    projectTitle: 'Aménagement',
    status: 'active',
    options: [{ id: 'a', label: 'A', votes: 3 }],
    questions: [
      {
        id: 'q1',
        title: 'Priorités ?',
        multiple: true,
        options: [{ id: 'o1', label: 'Parcs', votes: 5, icon: 'park' }],
      },
    ],
    createdBy: 'admin-uid-should-not-leak',
    totalVoters: 10,
    totalVoted: 5,
  };
  const payload = polls.publicPollPayloadFrom(poll);
  assert.deepEqual(payload.questions, poll.questions);
  assert.equal(payload.createdBy, undefined);
});

test('publicPollPayloadFrom returns null for non-publishable statuses', () => {
  assert.equal(polls.publicPollPayloadFrom({ id: 'p', status: 'draft' }), null);
  assert.equal(polls.publicPollPayloadFrom({ id: 'p', status: 'scheduled' }), null);
  assert.ok(polls.publicPollPayloadFrom({ id: 'p', status: 'active' }));
});

test('isPublicPollStatus only allows active, closed and archived', () => {
  assert.equal(polls.isPublicPollStatus('active'), true);
  assert.equal(polls.isPublicPollStatus('closed'), true);
  assert.equal(polls.isPublicPollStatus('archived'), true);
  assert.equal(polls.isPublicPollStatus('draft'), false);
  assert.equal(polls.isPublicPollStatus('scheduled'), false);
});
