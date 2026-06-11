import rateLimit from 'express-rate-limit';
import { RedisStore } from 'rate-limit-redis';
import { createClient } from 'redis';
import { env } from '../config/env.js';
import { logger } from '../services/logger.js';

const standardOptions = {
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  keyGenerator: (req) => req.ip || req.headers['x-forwarded-for'] || 'unknown-client',
};

let sharedStore;

if (env.rateLimitRedisUrl) {
  try {
    const redisClient = createClient({ url: env.rateLimitRedisUrl });
    redisClient.on('error', (error) => {
      logger.error({ err: error }, 'rate_limit_redis_error');
    });
    redisClient.connect().catch((error) => {
      logger.error({ err: error }, 'rate_limit_redis_connect_failed');
    });

    sharedStore = new RedisStore({
      sendCommand: (...args) => redisClient.sendCommand(args),
      prefix: 'rl:citoyen-peyi:',
    });
  } catch (error) {
    logger.error({ err: error }, 'rate_limit_redis_setup_failed');
  }
}

if (env.isProduction && !sharedStore) {
  // Sans Redis, le store memoire n'est pas partage entre instances Cloud Run
  // et le compteur repart a zero a chaque cold start : la protection est plus
  // faible mais reste fonctionnelle (max-instances volontairement bas). On
  // prefere demarrer avec un avertissement explicite plutot que de refuser le
  // boot et laisser tout le backend injoignable. Definir RATE_LIMIT_REDIS_URL
  // pour un rate limiting partage et robuste.
  logger.warn(
    'rate_limit_memory_store_fallback: RATE_LIMIT_REDIS_URL absent en production; '
    + 'rate limiting en memoire (par instance, non partage). '
    + 'Definir RATE_LIMIT_REDIS_URL (Memorystore/Upstash) pour un rate limiting partage.',
  );
}

const withStore = (options) => ({
  ...standardOptions,
  ...options,
  ...(sharedStore ? { store: sharedStore } : {}),
});

export const authRateLimiter = rateLimit({
  skip: (req) => req.path.startsWith('/api/health'),
  ...withStore({
  windowMs: 60 * 1000,
  max: 10,
  message: { message: 'Trop de tentatives, reessayez dans une minute.' },
  }),
});

export const voteAccessRateLimiter = rateLimit({
  skip: (req) => req.path.startsWith('/api/health'),
  ...withStore({
  windowMs: 60 * 1000,
  max: 30,
  message: { ok: false, errorCode: 'RATE_LIMITED', message: 'Trop de requetes, patientez un instant.' },
  }),
});

export const writeRateLimiter = rateLimit({
  skip: (req) => req.path.startsWith('/api/health'),
  ...withStore({
  windowMs: 60 * 1000,
  max: 60,
  message: { message: 'Trop de requetes, patientez un instant.' },
  }),
});
