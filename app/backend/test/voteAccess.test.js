import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.PARTICIPATION_PEPPER = process.env.PARTICIPATION_PEPPER || 'test-participation-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n';

const voteAccess = await import('../src/routes/voteAccess.js');

const clone = (value) => JSON.parse(JSON.stringify(value));

class FakeDocumentSnapshot {
  constructor(ref, data) {
    this.id = ref.id;
    this.exists = data !== undefined;
    this._data = data === undefined ? undefined : clone(data);
  }

  data() {
    return clone(this._data || {});
  }
}

class FakeDocumentRef {
  constructor(db, collectionName, id) {
    this.db = db;
    this.collectionName = collectionName;
    this.id = id;
  }
}

class FakeTransaction {
  constructor(db) {
    this.db = db;
    this.writes = [];
  }

  async get(ref) {
    return new FakeDocumentSnapshot(ref, this.db.read(ref));
  }

  set(ref, data, options = {}) {
    this.writes.push({ ref, data: clone(data), merge: options.merge === true });
  }
}

class FakeDb {
  constructor(seed = {}) {
    this.store = clone(seed);
    this.queue = Promise.resolve();
  }

  collection(collectionName) {
    return {
      doc: (id) => new FakeDocumentRef(this, collectionName, id),
    };
  }

  read(ref) {
    return this.store[ref.collectionName]?.[ref.id];
  }

  write(ref, data, { merge }) {
    this.store[ref.collectionName] ??= {};
    this.store[ref.collectionName][ref.id] = merge
      ? { ...(this.store[ref.collectionName][ref.id] || {}), ...data }
      : data;
  }

  async runTransaction(callback) {
    const run = async () => {
      const transaction = new FakeTransaction(this);
      const result = await callback(transaction);
      if (result.status === 200) {
        for (const write of transaction.writes) {
          this.write(write.ref, write.data, { merge: write.merge });
        }
      }
      return result;
    };
    const resultPromise = this.queue.then(run, run);
    this.queue = resultPromise.catch(() => {});
    return resultPromise;
  }
}

const seedVoteDb = () => new FakeDb({
  polls: {
    'poll-1': {
      id: 'poll-1',
      communeId: 'commune-1',
      status: 'active',
      options: [
        { id: 'opt-1', label: 'Oui', votes: 0 },
        { id: 'opt-2', label: 'Non', votes: 0 },
      ],
      totalVoted: 0,
    },
  },
  poll_participations: {},
  poll_ballots: {},
});

const tokenPayload = () => ({
  pollId: 'poll-1',
  communeId: 'commune-1',
  participationHash: voteAccess.createParticipationHash('poll-1', 'access-1'),
});

test('normalizeCode trims and uppercases values', () => {
  assert.equal(voteAccess.normalizeCode(' ab12cd34 '), 'AB12CD34');
});

test('hashCode uses peppered HMAC instead of legacy SHA-256', () => {
  const code = 'AB12CD34';
  const legacyHash = crypto.createHash('sha256').update(code).digest('hex');
  assert.notEqual(voteAccess.hashCode(code), legacyHash);
  assert.equal(voteAccess.hashCode(code), voteAccess.hashCode(' ab12cd34 '));
});

test('createParticipationHash uses a dedicated peppered HMAC', () => {
  const participationHash = voteAccess.createParticipationHash('poll-1', 'access-1');
  const legacyHash = crypto.createHash('sha256').update('poll-1:access-1').digest('hex');

  assert.match(participationHash, /^[a-f0-9]{64}$/);
  assert.notEqual(participationHash, legacyHash);
  assert.equal(participationHash, voteAccess.createParticipationHash('poll-1', 'access-1'));
});

test('createAnonymousBallotId returns an unlinkable 128-bit random id', () => {
  const firstId = voteAccess.createAnonymousBallotId();
  const secondId = voteAccess.createAnonymousBallotId();

  assert.match(firstId, /^[a-f0-9]{32}$/);
  assert.match(secondId, /^[a-f0-9]{32}$/);
  assert.notEqual(firstId, secondId);
  assert.equal(firstId.includes('poll-1'), false);
  assert.equal(firstId.includes('access-1'), false);
});

test('signPollAccessToken and verifyAccessToken roundtrip minimal vote payload', () => {
  const participationHash = voteAccess.createParticipationHash('poll-1', 'access-1');
  const token = voteAccess.signPollAccessToken({
    pollId: 'poll-1',
    communeId: 'commune-1',
    participationHash,
  });
  const payload = voteAccess.verifyAccessToken(token);

  assert.deepEqual(Object.keys(payload).sort(), ['communeId', 'exp', 'participationHash', 'pollId']);
  assert.equal(payload.pollId, 'poll-1');
  assert.equal(payload.communeId, 'commune-1');
  assert.equal(payload.participationHash, participationHash);
  assert.equal(payload.accessCodeId, undefined);
  assert.equal(payload.citizenFingerprintHash, undefined);
  assert.equal(payload.participations, undefined);
  assert.ok(payload.exp > Date.now());
});

test('verifyAccessToken rejects tampered token', () => {
  const token = voteAccess.signPollAccessToken({
    pollId: 'poll-1',
    communeId: 'commune-1',
    participationHash: voteAccess.createParticipationHash('poll-1', 'access-1'),
  });
  const tampered = `${token}broken`;
  assert.equal(voteAccess.verifyAccessToken(tampered), null);
});

test('optionBelongsToPoll validates option ownership', () => {
  const poll = { options: [{ id: 'opt-1' }, { id: 'opt-2' }] };
  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-2'), true);
  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-3'), false);
});

test('anonymous vote records separate participation from ballot', () => {
  const participation = voteAccess.buildParticipationRecord({
    pollId: 'poll-1',
    participationHash: 'a'.repeat(64),
    communeId: 'commune-1',
  });
  const ballot = voteAccess.buildAnonymousBallotRecord({
    pollId: 'poll-1',
    optionId: 'opt-1',
    communeId: 'commune-1',
  });

  assert.equal(participation.pollId, 'poll-1');
  assert.equal(participation.participationHash, 'a'.repeat(64));
  assert.equal(participation.optionId, undefined);
  assert.equal(participation.accessCodeId, undefined);
  assert.equal(participation.citizenFingerprintHash, undefined);

  assert.equal(ballot.pollId, 'poll-1');
  assert.equal(ballot.optionId, 'opt-1');
  assert.deepEqual(Object.keys(ballot).sort(), ['castAt', 'communeId', 'optionId', 'pollId']);
  for (const forbiddenKey of [
    'accessCodeId',
    'citizenFingerprintHash',
    'createdByControllerId',
    'createdByControllerName',
    'displayCodeMasked',
    'ip',
    'userAgent',
    'accessToken',
    'receiptId',
    'participationHash',
    'source',
  ]) {
    assert.equal(ballot[forbiddenKey], undefined);
  }
});

test('submit vote creates separated participation and anonymous ballot', async () => {
  const db = seedVoteDb();
  const result = await voteAccess.submitAnonymousVote({
    db,
    token: tokenPayload(),
    pollId: 'poll-1',
    optionId: 'opt-1',
  });

  assert.equal(result.status, 200);

  const participationDocs = Object.values(db.store.poll_participations);
  const ballotDocs = Object.values(db.store.poll_ballots);
  assert.equal(participationDocs.length, 1);
  assert.equal(ballotDocs.length, 1);

  assert.equal(participationDocs[0].pollId, 'poll-1');
  assert.equal(participationDocs[0].participationHash, tokenPayload().participationHash);
  assert.equal(participationDocs[0].optionId, undefined);

  assert.deepEqual(
    Object.keys(ballotDocs[0]).sort(),
    ['answers', 'castAt', 'communeId', 'optionId', 'pollId'],
  );
  assert.deepEqual(ballotDocs[0].answers, [
    { questionId: voteAccess.LEGACY_QUESTION_ID, optionIds: ['opt-1'] },
  ]);
  assert.equal(ballotDocs[0].accessCodeId, undefined);
  assert.equal(ballotDocs[0].citizenFingerprintHash, undefined);
  assert.equal(ballotDocs[0].participationHash, undefined);
});

test('submit vote rejects a second vote and keeps one anonymous ballot', async () => {
  const db = seedVoteDb();
  const first = await voteAccess.submitAnonymousVote({
    db,
    token: tokenPayload(),
    pollId: 'poll-1',
    optionId: 'opt-1',
  });
  const second = await voteAccess.submitAnonymousVote({
    db,
    token: tokenPayload(),
    pollId: 'poll-1',
    optionId: 'opt-2',
  });

  assert.equal(first.status, 200);
  assert.equal(second.status, 409);
  assert.equal(second.errorCode, 'ALREADY_VOTED');
  assert.equal(Object.keys(db.store.poll_ballots).length, 1);
});

test('concurrent submit attempts create only one anonymous ballot', async () => {
  const db = seedVoteDb();
  const [first, second] = await Promise.all([
    voteAccess.submitAnonymousVote({ db, token: tokenPayload(), pollId: 'poll-1', optionId: 'opt-1' }),
    voteAccess.submitAnonymousVote({ db, token: tokenPayload(), pollId: 'poll-1', optionId: 'opt-2' }),
  ]);

  assert.deepEqual([first.status, second.status].sort(), [200, 409]);
  assert.equal(Object.keys(db.store.poll_participations).length, 1);
  assert.equal(Object.keys(db.store.poll_ballots).length, 1);
});

test('public results remain available from poll aggregates', async () => {
  const db = seedVoteDb();
  await voteAccess.submitAnonymousVote({
    db,
    token: tokenPayload(),
    pollId: 'poll-1',
    optionId: 'opt-1',
  });

  const poll = db.store.polls['poll-1'];
  assert.equal(poll.totalVoted, 1);
  assert.deepEqual(
    poll.options.map((option) => ({ id: option.id, votes: option.votes })),
    [{ id: 'opt-1', votes: 1 }, { id: 'opt-2', votes: 0 }],
  );
});

test('isPollOpen respects active/open status and dates', () => {
  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: yesterday, closesAt: tomorrow }), true);
  assert.equal(voteAccess.isPollOpen({ status: 'closed', opensAt: yesterday, closesAt: tomorrow }), false);
  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: tomorrow, closesAt: tomorrow }), false);
});

test('isPollOpen accepts scheduled polls only after publication date', () => {
  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

  assert.equal(
    voteAccess.isPollOpen({
      status: 'scheduled',
      scheduledPublishDate: yesterday,
      opensAt: yesterday,
      closesAt: tomorrow,
    }),
    true,
  );
  assert.equal(
    voteAccess.isPollOpen({
      status: 'scheduled',
      scheduledPublishDate: tomorrow,
      opensAt: yesterday,
      closesAt: tomorrow,
    }),
    false,
  );
});
test('publicQuestionsForPoll falls back to a single legacy question', () => {
  const poll = {
    question: 'Quelle option ?',
    options: [
      { id: 'a', label: 'A', votes: 3, icon: 'park' },
      { id: 'b', label: 'B' },
    ],
  };
  const questions = voteAccess.publicQuestionsForPoll(poll);
  assert.equal(questions.length, 1);
  assert.equal(questions[0].id, voteAccess.LEGACY_QUESTION_ID);
  assert.equal(questions[0].multiple, false);
  assert.deepEqual(questions[0].options.map((o) => o.id), ['a', 'b']);
  assert.equal(questions[0].options[0].icon, 'park');
});

test('publicQuestionsForPoll exposes stored multi-step questions', () => {
  const poll = {
    questions: [
      {
        id: 'q1',
        title: 'Priorites ?',
        multiple: true,
        options: [
          { id: 'o1', label: 'Parcs', icon: 'park', votes: 9 },
          { id: 'o2', label: 'Eclairage', icon: 'lighting' },
        ],
      },
      { id: 'q2', title: 'Choix unique', options: [{ id: 'x', label: 'X' }, { id: 'y', label: 'Y' }] },
    ],
  };
  const questions = voteAccess.publicQuestionsForPoll(poll);
  assert.equal(questions.length, 2);
  assert.equal(questions[0].multiple, true);
  assert.equal(questions[1].multiple, false);
  // Les compteurs de votes ne sont pas exposes au citoyen.
  assert.equal(questions[0].options[0].votes, undefined);
});

const surveyPoll = {
  questions: [
    {
      id: 'q1',
      title: 'Multi',
      multiple: true,
      options: [{ id: 'o1', label: 'A', votes: 1 }, { id: 'o2', label: 'B' }, { id: 'o3', label: 'C' }],
    },
    {
      id: 'q2',
      title: 'Simple',
      multiple: false,
      options: [{ id: 'x', label: 'X' }, { id: 'y', label: 'Y' }],
    },
  ],
};

test('validateAnswers accepts a complete valid survey answer set', () => {
  const result = voteAccess.validateAnswers(surveyPoll, [
    { questionId: 'q1', optionIds: ['o1', 'o3'] },
    { questionId: 'q2', optionIds: ['y'] },
  ]);
  assert.equal(result.error, undefined);
  assert.deepEqual(result.answers.get('q1'), ['o1', 'o3']);
  assert.deepEqual(result.answers.get('q2'), ['y']);
});

test('validateAnswers rejects incomplete, unknown or plural answers', () => {
  assert.ok(voteAccess.validateAnswers(surveyPoll, [
    { questionId: 'q1', optionIds: ['o1'] },
  ]).error, 'toutes les questions doivent etre repondues');
  assert.ok(voteAccess.validateAnswers(surveyPoll, [
    { questionId: 'q1', optionIds: ['o1'] },
    { questionId: 'q2', optionIds: ['x', 'y'] },
  ]).error, 'choix unique impose une seule option');
  assert.ok(voteAccess.validateAnswers(surveyPoll, [
    { questionId: 'q1', optionIds: ['nope'] },
    { questionId: 'q2', optionIds: ['x'] },
  ]).error, 'option inconnue rejetee');
  assert.ok(voteAccess.validateAnswers(surveyPoll, [
    { questionId: 'autre', optionIds: ['o1'] },
    { questionId: 'q2', optionIds: ['x'] },
  ]).error, 'question inconnue rejetee');
  assert.ok(voteAccess.validateAnswers(surveyPoll, []).error, 'reponses vides rejetees');
});

test('validateAnswers handles legacy polls through the pseudo-question', () => {
  const legacy = { question: 'Q', options: [{ id: 'a', label: 'A' }, { id: 'b', label: 'B' }] };
  const ok = voteAccess.validateAnswers(legacy, [
    { questionId: voteAccess.LEGACY_QUESTION_ID, optionIds: ['b'] },
  ]);
  assert.deepEqual(ok.answers.get(voteAccess.LEGACY_QUESTION_ID), ['b']);
  const tooMany = voteAccess.validateAnswers(legacy, [
    { questionId: voteAccess.LEGACY_QUESTION_ID, optionIds: ['a', 'b'] },
  ]);
  assert.ok(tooMany.error);
});

test('applyAnswersToQuestions increments only selected options', () => {
  const answers = new Map([['q1', ['o1', 'o3']], ['q2', ['y']]]);
  const updated = voteAccess.applyAnswersToQuestions(surveyPoll.questions, answers);
  assert.deepEqual(updated[0].options.map((o) => o.votes ?? 0), [2, 0, 1]);
  assert.deepEqual(updated[1].options.map((o) => o.votes ?? 0), [0, 1]);
  // L'original n'est pas mute.
  assert.equal(surveyPoll.questions[0].options[0].votes, 1);
});

test('submit vote records survey answers and increments per-question counters', async () => {
  const db = new FakeDb({
    polls: {
      'poll-s': {
        id: 'poll-s',
        communeId: 'commune-1',
        status: 'active',
        question: 'Q1 miroir',
        options: [
          { id: 'o1', label: 'Parcs', votes: 0 },
          { id: 'o2', label: 'Eclairage', votes: 0 },
        ],
        questions: [
          {
            id: 'q1',
            title: 'Priorites ?',
            multiple: true,
            options: [
              { id: 'o1', label: 'Parcs', votes: 0 },
              { id: 'o2', label: 'Eclairage', votes: 0 },
              { id: 'o3', label: 'Jeux', votes: 0 },
            ],
          },
          {
            id: 'q2',
            title: 'Satisfait ?',
            multiple: false,
            options: [
              { id: 'yes', label: 'Oui', votes: 0 },
              { id: 'no', label: 'Non', votes: 0 },
            ],
          },
        ],
        totalVoted: 0,
      },
    },
    poll_participations: {},
    poll_ballots: {},
  });
  const token = {
    pollId: 'poll-s',
    communeId: 'commune-1',
    participationHash: voteAccess.createParticipationHash('poll-s', 'access-1'),
  };

  const missing = await voteAccess.submitAnonymousVote({
    db,
    token,
    pollId: 'poll-s',
    optionId: '',
    answers: [{ questionId: 'q1', optionIds: ['o1'] }],
  });
  assert.equal(missing.status, 400, 'q2 sans reponse doit etre refusee');

  const result = await voteAccess.submitAnonymousVote({
    db,
    token,
    pollId: 'poll-s',
    optionId: '',
    answers: [
      { questionId: 'q1', optionIds: ['o1', 'o3'] },
      { questionId: 'q2', optionIds: ['no'] },
    ],
  });
  assert.equal(result.status, 200);

  const poll = db.store.polls['poll-s'];
  assert.deepEqual(poll.questions[0].options.map((o) => o.votes), [1, 0, 1]);
  assert.deepEqual(poll.questions[1].options.map((o) => o.votes), [0, 1]);
  // Miroir historique : options refletent la premiere question.
  assert.deepEqual(poll.options.map((o) => o.votes), [1, 0, 1]);
  assert.equal(poll.totalVoted, 1);

  const ballot = Object.values(db.store.poll_ballots)[0];
  assert.deepEqual(ballot.answers, [
    { questionId: 'q1', optionIds: ['o1', 'o3'] },
    { questionId: 'q2', optionIds: ['no'] },
  ]);
  assert.equal(ballot.optionId, 'o1');
});

test('legacy single-option submit maps to the stored single question and rejects multi-question polls', async () => {
  const single = {
    polls: {
      'poll-q1': {
        id: 'poll-q1', communeId: 'commune-1', status: 'active',
        options: [{ id: 'a', label: 'A', votes: 0 }, { id: 'b', label: 'B', votes: 0 }],
        questions: [{ id: 'q1', title: 'Q', multiple: false, options: [{ id: 'a', label: 'A', votes: 0 }, { id: 'b', label: 'B', votes: 0 }] }],
        totalVoted: 0,
      },
    },
    poll_participations: {}, poll_ballots: {},
  };
  const db = new FakeDb(single);
  const token = { pollId: 'poll-q1', communeId: 'commune-1', participationHash: voteAccess.createParticipationHash('poll-q1', 'a1') };
  const ok = await voteAccess.submitAnonymousVote({ db, token, pollId: 'poll-q1', optionId: 'b' });
  assert.equal(ok.status, 200);
  assert.deepEqual(db.store.polls['poll-q1'].questions[0].options.map((o) => o.votes), [0, 1]);

  const multi = JSON.parse(JSON.stringify(single));
  multi.polls['poll-q1'].questions.push({ id: 'q2', title: 'Q2', options: [{ id: 'x', label: 'X', votes: 0 }, { id: 'y', label: 'Y', votes: 0 }] });
  const db2 = new FakeDb(multi);
  const token2 = { pollId: 'poll-q1', communeId: 'commune-1', participationHash: voteAccess.createParticipationHash('poll-q1', 'a2') };
  const refused = await voteAccess.submitAnonymousVote({ db: db2, token: token2, pollId: 'poll-q1', optionId: 'b' });
  assert.equal(refused.status, 400);
});
