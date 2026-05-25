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
      'req.body.accessKey',
      'req.body.code',
      'req.body.accessToken',
      'res.headers["set-cookie"]',
    ],
    censor: '[REDACTED]',
  },
});

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
      url: req.url,
      remoteAddress: req.remoteAddress,
    }),
  },
});
