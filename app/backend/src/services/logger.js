import pino from 'pino';
import pinoHttp from 'pino-http';
import { env } from '../config/env.js';

export const logger = pino({
  level: env.logLevel,
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers["x-super-admin-key"]',
      'req.headers.cookie',
      'req.body',
      'req.body.accessKey',
      'req.body.code',
      'req.body.accessToken',
      'req.body.customToken',
      'req.body.accessCodeId',
      'req.body.accessCodeHash',
      'req.body.citizenFingerprintHash',
      'req.body.participationHash',
      'req.body.adminAccessKey',
      'req.body.fingerprint',
      'req.body.phone',
      'req.body.phoneSuffix',
      'req.body.phoneLastTwo',
      'req.body.birthYear',
      'req.body.sourceKeyMasked',
      'accessCode',
      'accessCodeId',
      'accessCodeHash',
      'citizenFingerprintHash',
      'participationHash',
      'code',
      'customToken',
      'accessKey',
      'adminAccessKey',
      'fingerprint',
      'phone',
      'phoneSuffix',
      'phoneLastTwo',
      'birthYear',
      'sourceKeyMasked',
      '*.accessCode',
      '*.accessCodeId',
      '*.accessCodeHash',
      '*.citizenFingerprintHash',
      '*.participationHash',
      '*.code',
      '*.customToken',
      '*.accessKey',
      '*.fingerprint',
      '*.phone',
      '*.phoneSuffix',
      '*.phoneLastTwo',
      '*.birthYear',
      '*.sourceKeyMasked',
      'res.headers["set-cookie"]',
    ],
    censor: '[REDACTED]',
  },
});

export const sanitizeRequestUrl = (url = '') => String(url)
  .replace(/\/api\/citizen-access\/codes\/[^/]+\/revoke/g, '/api/citizen-access/codes/[REDACTED]/revoke')
  .replace(/([?&]code=)[^&]+/gi, '$1[REDACTED]');

export const httpLogger = pinoHttp({
  logger,
  customLogLevel: (_req, res, err) => {
    if (err || res.statusCode >= 500) return 'error';
    if (res.statusCode >= 400) return 'warn';
    return 'info';
  },
  serializers: {
    req: (req) => ({
      method: req.method,
      url: sanitizeRequestUrl(req.url),
      remoteAddress: req.remoteAddress,
    }),
  },
});
