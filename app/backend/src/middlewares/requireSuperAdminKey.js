import crypto from 'crypto';
import { env, isSuperAdminConfigured } from '../config/env.js';

const safeEquals = (left, right) => {
  const leftBuffer = Buffer.from(String(left || ''), 'utf8');
  const rightBuffer = Buffer.from(String(right || ''), 'utf8');
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(leftBuffer, rightBuffer);
};

export const hasValidSuperAdminKey = (req) => {
  const providedKey = typeof req.headers['x-super-admin-key'] === 'string'
    ? req.headers['x-super-admin-key'].trim()
    : '';

  return Boolean(providedKey && safeEquals(providedKey, env.superAdminKey));
};

export const requireSuperAdminKey = (req, res, next) => {
  if (!isSuperAdminConfigured()) {
    return res.status(503).json({ message: 'SUPER_ADMIN_KEY est absent sur le backend.' });
  }

  if (!hasValidSuperAdminKey(req)) {
    return res.status(401).json({ message: 'Cle super administrateur invalide.' });
  }

  return next();
};
