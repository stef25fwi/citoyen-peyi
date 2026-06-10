const BASE_URL = process.env.LOAD_SMOKE_BASE_URL || 'http://127.0.0.1:4000';
const ENDPOINT = process.env.LOAD_SMOKE_ENDPOINT || '/api/health/live';

const REQUESTS = Number.parseInt(process.env.LOAD_SMOKE_REQUESTS || '60', 10);
const CONCURRENCY = Number.parseInt(process.env.LOAD_SMOKE_CONCURRENCY || '6', 10);

const ERROR_RATE_MAX = Number.parseFloat(process.env.LOAD_SMOKE_ERROR_RATE_MAX || '0.02');
const P95_MAX_MS = Number.parseFloat(process.env.LOAD_SMOKE_P95_MAX_MS || '1000');

const url = `${BASE_URL}${ENDPOINT}`;

function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1);
  return sorted[index];
}

async function hit(index) {
  const started = performance.now();

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        accept: 'application/json',
        'user-agent': 'citoyen-peyi-load-smoke-ci',
      },
    });

    const durationMs = performance.now() - started;
    const body = await response.text().catch(() => '');

    return {
      index,
      ok: response.ok,
      status: response.status,
      durationMs,
      error: response.ok ? null : `HTTP ${response.status}`,
      bodyPreview: body.slice(0, 160),
    };
  } catch (error) {
    return {
      index,
      ok: false,
      status: 0,
      durationMs: performance.now() - started,
      error: error?.message || String(error),
      bodyPreview: '',
    };
  }
}

async function runPool() {
  const results = [];
  let nextIndex = 0;

  async function worker() {
    while (nextIndex < REQUESTS) {
      const index = nextIndex;
      nextIndex += 1;
      results.push(await hit(index));
    }
  }

  const workers = Array.from(
    { length: Math.min(CONCURRENCY, REQUESTS) },
    () => worker(),
  );

  await Promise.all(workers);
  return results.sort((a, b) => a.index - b.index);
}

const results = await runPool();

const durations = results.map((result) => result.durationMs);
const failures = results.filter((result) => !result.ok);
const errorRate = failures.length / results.length;
const avg = durations.reduce((sum, value) => sum + value, 0) / durations.length;
const p95 = percentile(durations, 95);
const p99 = percentile(durations, 99);

const summary = {
  kind: 'load-smoke-test',
  endpoint: url,
  requests: REQUESTS,
  concurrency: CONCURRENCY,
  total: results.length,
  failures: failures.length,
  errorRate,
  avg,
  p95,
  p99,
  failureSamples: failures.slice(0, 8).map((failure) => ({
    index: failure.index,
    status: failure.status,
    durationMs: Number(failure.durationMs.toFixed(2)),
    error: failure.error,
    bodyPreview: failure.bodyPreview,
  })),
};

console.log(JSON.stringify(summary));

if (errorRate > ERROR_RATE_MAX) {
  throw new Error(`Error rate too high: ${errorRate.toFixed(4)} > ${ERROR_RATE_MAX}`);
}

if (p95 > P95_MAX_MS) {
  throw new Error(`P95 latency too high: ${p95.toFixed(2)}ms > ${P95_MAX_MS}ms`);
}
