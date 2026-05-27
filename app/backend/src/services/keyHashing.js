import crypto from 'crypto';
import { env } from '../config/env.js';

const normalize = (value) => String(value || '').trim().toUpperCase();

const ensurePepper = (pepper, name) => {
  if (!pepper) {
    throw new Error(`${name} is required`);
  }
  return pepper;
};

export const hashLegacySha256 = (value) => crypto
  .createHash('sha256')
  .update(normalize(value))
  .digest('hex');

export const hashAdminAccessKey = (value) => crypto
  .createHmac('sha256', ensurePepper(env.adminAccessPepper, 'ADMIN_ACCESS_PEPPER'))
  .update(normalize(value))
  .digest('hex');

export const hashControllerCode = (value) => crypto
  .createHmac('sha256', ensurePepper(env.controllerCodePepper, 'CONTROLLER_CODE_PEPPER'))
  .update(normalize(value))
  .digest('hex');

export const matchesStoredHash = (value, storedHash, preferredHash) => {
  if (!storedHash) return false;
  const normalizedStored = String(storedHash);
  return normalizedStored === preferredHash || normalizedStored === hashLegacySha256(value);
};