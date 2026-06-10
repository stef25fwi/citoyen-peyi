import pino from 'pino';
import pinoHttp from 'pino-http';
import { env } from '../config/env.js';

export const sensitiveLogFields = new Set([
  'accesscode',
  'accesscodeid',
  'accesscodehash',
  'citizenfingerprinthash',
  'participationhash',
  'accesstoken',
  'optionid',
  'authorization',
  'xsuperadminkey',
]);

const normalizeFieldName = (field) => String(field || '').toLowerCase().replace(/[^a-z0-9]/g, '');

const isPlainObject = (value) => {
  if (Object.prototype.toString.call(value) !== '[object Object]') return false;
  // N'accepte que les objets "simples" (litteraux / Object.create(null)).
  // Les instances natives (req, res, socket...) ne sont pas parcourues: elles
  // contiennent des references circulaires qui feraient deborder la pile.
  const proto = Object.getPrototypeOf(value);
  return proto === null || proto === Object.prototype;
};

export const sanitizeLogPayload = (value, seen = new WeakSet()) => {
  if (Array.isArray(value)) {
    if (seen.has(value)) return '[Circular]';
    seen.add(value);
    const sanitized = value.map((item) => sanitizeLogPayload(item, seen));
    seen.delete(value);
    return sanitized;
  }

  if (value instanceof Error || !isPlainObject(value)) {
    return value;
  }

  if (seen.has(value)) return '[Circular]';
  seen.add(value);
  const sanitized = Object.fromEntries(
    Object.entries(value).map(([key, item]) => [
      key,
      sensitiveLogFields.has(normalizeFieldName(key))
        ? '[REDACTED]'
        : sanitizeLogPayload(item, seen),
    ]),
  );
  seen.delete(value);
  return sanitized;
};

export const logger = pino({
  level: env.logLevel,
  hooks: {
    logMethod(inputArgs, method) {
      const sanitizedArgs = inputArgs.map((arg) => sanitizeLogPayload(arg));
      method.apply(this, sanitizedArgs);
    },
  },
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.Authorization',
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
      'req.body.optionId',
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
      'accessToken',
      'optionId',
      'authorization',
      'Authorization',
      'x-super-admin-key',
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
      '*.accessToken',
      '*.optionId',
      '*.authorization',
      '*.Authorization',
      '*["x-super-admin-key"]',
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
    }),
  },
});
