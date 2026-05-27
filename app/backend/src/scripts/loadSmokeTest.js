import { spawn } from 'node:child_process';

const BASE_URL = process.env.LOAD_TEST_BASE_URL || 'http://127.0.0.1:4000';
const ENDPOINT = '/api/health/live';
const REQUESTS = Number(process.env.LOAD_TEST_REQUESTS || 120);
const CONCURRENCY = Number(process.env.LOAD_TEST_CONCURRENCY || 20);
const P95_MAX_MS = Number(process.env.LOAD_TEST_P95_MAX_MS || 450);
const P99_MAX_MS = Number(process.env.LOAD_TEST_P99_MAX_MS || 900);
const ERROR_RATE_MAX = Number(process.env.LOAD_TEST_ERROR_RATE_MAX || 0.01);

const sleep = (ms) => new Promise((resolve) => {
  setTimeout(resolve, ms);
});

const quantile = (values, q) => {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.floor(q * (sorted.length - 1)));
  return sorted[index];
};

const runRequest = async (url) => {
  const start = process.hrtime.bigint();
  try {
    const response = await fetch(url);
    await response.arrayBuffer();
    const elapsedMs = Number(process.hrtime.bigint() - start) / 1_000_000;
    return { ok: response.ok, elapsedMs };
  } catch {
    const elapsedMs = Number(process.hrtime.bigint() - start) / 1_000_000;
    return { ok: false, elapsedMs };
  }
};

const runLoad = async (url) => {
  let next = 0;
  const durations = [];
  let failures = 0;

  const worker = async () => {
    while (next < REQUESTS) {
      const index = next;
      next += 1;
      if (index >= REQUESTS) return;
      const result = await runRequest(url);
      durations.push(result.elapsedMs);
      if (!result.ok) failures += 1;
    }
  };

  await Promise.all(Array.from({ length: CONCURRENCY }, () => worker()));

  const p95 = quantile(durations, 0.95);
  const p99 = quantile(durations, 0.99);
  const avg = durations.reduce((sum, value) => sum + value, 0) / Math.max(durations.length, 1);
  const errorRate = failures / Math.max(durations.length, 1);

  return {
    total: durations.length,
    failures,
    errorRate,
    avg,
    p95,
    p99,
  };
};

const waitForServer = async (url) => {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const result = await runRequest(url);
    if (result.ok) return;
    await sleep(200);
  }
  throw new Error(`Server did not become ready on ${url}`);
};

const env = {
  ...process.env,
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: process.env.PORT || '4000',
  CORS_ORIGIN: process.env.CORS_ORIGIN || 'http://localhost:8081',
  SUPER_ADMIN_KEY: process.env.SUPER_ADMIN_KEY || 'test-super-admin-key',
  VOTE_ACCESS_TOKEN_SECRET: process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret-12345678901234567890123456789012',
  ACCESS_CODE_PEPPER: process.env.ACCESS_CODE_PEPPER || 'test-access-pepper-12345678901234567890123456789012',
  CITIZEN_FINGERPRINT_PEPPER: process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-fingerprint-pepper-1234567890123456789012345678',
  ADMIN_ACCESS_PEPPER: process.env.ADMIN_ACCESS_PEPPER || 'test-admin-pepper-1234567890123456789012345678901234',
  CONTROLLER_CODE_PEPPER: process.env.CONTROLLER_CODE_PEPPER || 'test-controller-pepper-123456789012345678901234567890',
  FIREBASE_ADMIN_PROJECT_ID: process.env.FIREBASE_ADMIN_PROJECT_ID || 'demo-project',
  FIREBASE_ADMIN_CLIENT_EMAIL: process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'demo@example.com',
  FIREBASE_ADMIN_PRIVATE_KEY: process.env.FIREBASE_ADMIN_PRIVATE_KEY || 'PRIVATE_KEY',
};

const server = spawn(process.execPath, ['src/index.js'], {
  env,
  stdio: ['ignore', 'pipe', 'pipe'],
});

server.stdout.on('data', () => {});
server.stderr.on('data', () => {});

try {
  await waitForServer(`${BASE_URL}${ENDPOINT}`);
  const result = await runLoad(`${BASE_URL}${ENDPOINT}`);

  console.log(JSON.stringify({
    kind: 'load-smoke-test',
    endpoint: `${BASE_URL}${ENDPOINT}`,
    requests: REQUESTS,
    concurrency: CONCURRENCY,
    ...result,
  }));

  if (result.errorRate > ERROR_RATE_MAX) {
    throw new Error(`Error rate too high: ${result.errorRate.toFixed(4)} > ${ERROR_RATE_MAX}`);
  }
  if (result.p95 > P95_MAX_MS) {
    throw new Error(`p95 too high: ${result.p95.toFixed(1)}ms > ${P95_MAX_MS}ms`);
  }
  if (result.p99 > P99_MAX_MS) {
    throw new Error(`p99 too high: ${result.p99.toFixed(1)}ms > ${P99_MAX_MS}ms`);
  }
} finally {
  server.kill('SIGTERM');
}
