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
  // Le memory store n'est pas partage entre instances Cloud Run et peut etre
  // sature trivialement; on refuse le boot pour eviter une fausse protection.
  throw new Error('RATE_LIMIT_REDIS_URL est requis en production pour partager le rate limiter entre instances.');
}

const withStore = (options) => ({
  ...standardOptions,
  ...options,
  ...(sharedStore ? { store: sharedStore } : {}),
});

export const authRateLimiter = rateLimit({
  ...withStore({
  windowMs: 60 * 1000,
  max: 10,
  message: { message: 'Trop de tentatives, reessayez dans une minute.' },
  }),
});

export const voteAccessRateLimiter = rateLimit({
  ...withStore({
  windowMs: 60 * 1000,
  max: 30,
  message: { ok: false, errorCode: 'RATE_LIMITED', message: 'Trop de requetes, patientez un instant.' },
  }),
});

export const writeRateLimiter = rateLimit({
  ...withStore({
  windowMs: 60 * 1000,
  max: 60,
  message: { message: 'Trop de requetes, patientez un instant.' },
  }),
});
