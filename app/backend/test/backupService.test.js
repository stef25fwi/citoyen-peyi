import test from 'node:test';
import assert from 'node:assert/strict';

const {
  serializeValue,
  serializeDocData,
  deserializeValue,
  deserializeDocData,
  comparableTime,
  planRestore,
  collectSnapshot,
  restoreSnapshot,
} = await import('../src/services/backupService.js');

// Faux Timestamp Firestore (duck-typing: .toDate + .fromDate).
class FakeTimestamp {
  constructor(date) { this._date = date; }
  toDate() { return this._date; }
  static fromDate(date) { return new FakeTimestamp(date); }
}

test('serialize/deserialize round-trip preserves timestamps and nested structures', () => {
  const original = {
    title: 'Consultation',
    createdAt: new FakeTimestamp(new Date('2026-01-02T03:04:05.000Z')),
    options: [
      { id: 'opt-1', label: 'Oui', votes: 3 },
      { id: 'opt-2', label: 'Non', votes: 1 },
    ],
    metadata: { nested: { at: new Date('2026-02-03T00:00:00.000Z'), flag: true } },
    nothing: null,
  };

  const serialized = serializeDocData(original);
  // Les timestamps deviennent des marqueurs JSON sérialisables.
  assert.equal(serialized.createdAt.$ts, '2026-01-02T03:04:05.000Z');
  assert.equal(serialized.metadata.nested.at.$ts, '2026-02-03T00:00:00.000Z');
  assert.deepEqual(JSON.parse(JSON.stringify(serialized)), serialized);

  const restored = deserializeDocData(serialized, { Timestamp: FakeTimestamp });
  assert.ok(restored.createdAt instanceof FakeTimestamp);
  assert.equal(restored.createdAt.toDate().toISOString(), '2026-01-02T03:04:05.000Z');
  assert.equal(restored.options[1].label, 'Non');
  assert.equal(restored.metadata.nested.flag, true);
  assert.equal(restored.nothing, null);
});

test('serializeValue leaves primitives untouched', () => {
  assert.equal(serializeValue('x'), 'x');
  assert.equal(serializeValue(42), 42);
  assert.equal(serializeValue(false), false);
  assert.equal(deserializeValue('x', { Timestamp: FakeTimestamp }), 'x');
});

test('comparableTime reads updatedAt across $ts, Timestamp, Date and ISO forms', () => {
  assert.equal(comparableTime({ updatedAt: { $ts: '2026-01-01T00:00:00.000Z' } }), Date.parse('2026-01-01T00:00:00.000Z'));
  assert.equal(comparableTime({ updatedAt: new Date('2026-01-01T00:00:00.000Z') }), Date.parse('2026-01-01T00:00:00.000Z'));
  assert.equal(comparableTime({ createdAt: '2026-01-01T00:00:00.000Z' }), Date.parse('2026-01-01T00:00:00.000Z'));
  assert.equal(comparableTime({}), 0);
});

test('planRestore creates missing docs and is idempotent on equal docs', () => {
  const backup = [
    { id: 'a', data: { updatedAt: { $ts: '2026-01-02T00:00:00.000Z' } } },
    { id: 'b', data: { updatedAt: { $ts: '2026-01-02T00:00:00.000Z' } } },
  ];
  const existing = [
    { id: 'a', data: { updatedAt: { $ts: '2026-01-02T00:00:00.000Z' } } },
  ];
  const plan = planRestore({ existing, backup, mode: 'merge' });
  // 'b' n'existe pas -> ecrit ; 'a' identique -> ecrit (pas plus recent) ; rien supprime.
  assert.deepEqual(plan.writes.map((d) => d.id).sort(), ['a', 'b']);
  assert.equal(plan.deletes.length, 0);
});

test('planRestore skips documents that are newer than the snapshot (anti-overwrite)', () => {
  const backup = [{ id: 'a', data: { updatedAt: { $ts: '2026-01-01T00:00:00.000Z' } } }];
  const existing = [{ id: 'a', data: { updatedAt: { $ts: '2026-06-01T00:00:00.000Z' } } }];

  const merge = planRestore({ existing, backup, mode: 'merge' });
  assert.equal(merge.writes.length, 0);
  assert.deepEqual(merge.skipped, [{ id: 'a', reason: 'existing_newer' }]);

  // force ignore la garde anti-ecrasement.
  const forced = planRestore({ existing, backup, mode: 'merge', force: true });
  assert.equal(forced.writes.length, 1);
});

test('planRestore mirror deletes documents absent from the snapshot', () => {
  const backup = [{ id: 'a', data: {} }];
  const existing = [{ id: 'a', data: {} }, { id: 'orphan', data: {} }];
  const plan = planRestore({ existing, backup, mode: 'mirror' });
  assert.deepEqual(plan.deletes, ['orphan']);
});

// ---------- Fake Firestore minimal ----------

class FakeColl {
  constructor(db, name) { this.db = db; this.name = name; }

  async get() {
    const obj = this.db.data[this.name] || {};
    return { docs: Object.entries(obj).map(([id, data]) => ({ id, data: () => data })) };
  }

  doc(id) { return { _loc: { coll: this.name, id }, id }; }
}

class FakeDb {
  constructor(data) {
    this.data = data;
    this.writes = [];
    this.deletes = [];
  }

  collection(name) { return new FakeColl(this, name); }

  async getAll(...refs) {
    return refs.map((ref) => {
      const data = this.data[ref._loc.coll]?.[ref._loc.id];
      return { id: ref._loc.id, exists: data !== undefined, data: () => data };
    });
  }

  batch() {
    const ops = [];
    const self = this;
    return {
      set(ref, data) { ops.push(['set', ref, data]); },
      delete(ref) { ops.push(['delete', ref]); },
      async commit() {
        for (const [kind, ref, data] of ops) {
          if (kind === 'set') self.writes.push({ coll: ref._loc.coll, id: ref._loc.id, data });
          else self.deletes.push({ coll: ref._loc.coll, id: ref._loc.id });
        }
      },
    };
  }
}

const TEST_SPECS = [
  { key: 'polls', scopeField: 'communeId' },
  { key: 'communeAdmins', scopeField: 'communeCode' },
];

test('collectSnapshot serializes selected collections with counts', async () => {
  const db = new FakeDb({
    polls: {
      'poll-1': { id: 'poll-1', communeId: '97211', createdAt: new FakeTimestamp(new Date('2026-01-01T00:00:00.000Z')) },
    },
    communeAdmins: {
      'adm-1': { communeCode: '97211', accessKeyHash: 'a'.repeat(64) },
    },
  });

  const snapshot = await collectSnapshot({ db, specs: TEST_SPECS, now: new Date('2026-06-16T00:00:00.000Z') });
  assert.equal(snapshot.version, 1);
  assert.equal(snapshot.totalDocuments, 2);
  assert.equal(snapshot.counts.polls, 1);
  assert.equal(snapshot.collections.polls[0].data.createdAt.$ts, '2026-01-01T00:00:00.000Z');
});

test('restoreSnapshot dry-run reports without writing', async () => {
  const db = new FakeDb({ polls: {} });
  const snapshot = {
    version: 1,
    collections: { polls: [{ id: 'poll-1', data: { id: 'poll-1' } }] },
  };
  const report = await restoreSnapshot({
    db, snapshot, Timestamp: FakeTimestamp, specs: TEST_SPECS, options: { dryRun: true },
  });
  assert.equal(report.dryRun, true);
  assert.equal(report.collections.polls.writes, 1);
  assert.equal(db.writes.length, 0); // aucune ecriture en dry-run
});

test('restoreSnapshot apply writes deserialized documents', async () => {
  const db = new FakeDb({ polls: {} });
  const snapshot = {
    version: 1,
    collections: {
      polls: [{ id: 'poll-1', data: { id: 'poll-1', createdAt: { $ts: '2026-01-01T00:00:00.000Z' } } }],
    },
  };
  const report = await restoreSnapshot({
    db, snapshot, Timestamp: FakeTimestamp, specs: TEST_SPECS, options: { dryRun: false },
  });
  assert.equal(report.totals.writes, 1);
  assert.equal(db.writes.length, 1);
  assert.equal(db.writes[0].id, 'poll-1');
  // Le timestamp a ete rehydrate en (Fake)Timestamp avant ecriture.
  assert.ok(db.writes[0].data.createdAt instanceof FakeTimestamp);
});
