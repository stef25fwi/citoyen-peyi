import rateLimit from 'express-rate-limit';

const standardOptions = {
  standardHeaders: 'draft-7',
  legacyHeaders: false,
};

export const authRateLimiter = rateLimit({
  ...standardOptions,
  windowMs: 60 * 1000,
  max: 10,
  message: { message: 'Trop de tentatives, reessayez dans une minute.' },
});

export const voteAccessRateLimiter = rateLimit({
  ...standardOptions,
  windowMs: 60 * 1000,
  max: 30,
  message: { ok: false, errorCode: 'RATE_LIMITED', message: 'Trop de requetes, patientez un instant.' },
});

export const writeRateLimiter = rateLimit({
  ...standardOptions,
  windowMs: 60 * 1000,
  max: 60,
  message: { message: 'Trop de requetes, patientez un instant.' },
});
