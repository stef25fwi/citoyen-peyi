import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const currentDir = path.dirname(fileURLToPath(import.meta.url));

const parseEnvLine = (line) => {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) return null;
  const separatorIndex = trimmed.indexOf('=');
  if (separatorIndex === -1) return null;
  const key = trimmed.substring(0, separatorIndex).trim();
  let value = trimmed.substring(separatorIndex + 1).trim();
  if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
    value = value.substring(1, value.length - 1);
  }
  return key ? [key, value] : null;
};

const loadEnvFile = (filePath) => {
  if (!fs.existsSync(filePath)) return;
  const content = fs.readFileSync(filePath, 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const parsed = parseEnvLine(line);
    if (!parsed) continue;
    const [key, value] = parsed;
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
};

loadEnvFile(path.resolve(currentDir, '../../../../.env'));
loadEnvFile(path.resolve(currentDir, '../../.env'));

const defaultCorsOrigins = [
  'http://localhost:5173',
  'http://localhost:8081',
  'http://127.0.0.1:8081',
];

const optional = (value) => (typeof value === 'string' && value.trim().length > 0 ? value.trim() : '');

const parseCorsOrigins = (value) => {
  const configured = String(value || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  return configured.length > 0 ? configured : defaultCorsOrigins;
};

const hasGoogleApplicationCredentials = () => {
  const path = optional(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  return Boolean(path && fs.existsSync(path));
};

const hasExplicitFirebaseAdminCredentials = () => Boolean(
  optional(process.env.FIREBASE_ADMIN_PROJECT_ID)
  && optional(process.env.FIREBASE_ADMIN_CLIENT_EMAIL)
  && optional(process.env.FIREBASE_ADMIN_PRIVATE_KEY),
);

export const env = {
  nodeEnv: optional(process.env.NODE_ENV) || 'development',
  port: Number(process.env.PORT || 4000),
  apiBaseUrl: optional(process.env.API_BASE_URL),
  corsOrigins: parseCorsOrigins(process.env.CORS_ORIGIN),
  superAdminKey: optional(process.env.SUPER_ADMIN_KEY),
  adminAccessKey: optional(process.env.ADMIN_ACCESS_KEY),
  googleApplicationCredentials: optional(process.env.GOOGLE_APPLICATION_CREDENTIALS),
  firebaseAdminProjectId: optional(process.env.FIREBASE_ADMIN_PROJECT_ID),
  firebaseAdminClientEmail: optional(process.env.FIREBASE_ADMIN_CLIENT_EMAIL),
  firebaseAdminPrivateKey: optional(process.env.FIREBASE_ADMIN_PRIVATE_KEY),
};

export const isSuperAdminConfigured = () => Boolean(env.superAdminKey);

export const isFirebaseAdminConfigured = () => hasGoogleApplicationCredentials() || hasExplicitFirebaseAdminCredentials();

export const validateEnv = () => {
  const errors = [];

  if (!isSuperAdminConfigured()) {
    errors.push('SUPER_ADMIN_KEY est requis pour proteger les routes super administrateur.');
  }

  if (!isFirebaseAdminConfigured()) {
    errors.push(
      'Firebase Admin doit etre configure avec GOOGLE_APPLICATION_CREDENTIALS pointant vers un fichier existant, ou avec FIREBASE_ADMIN_PROJECT_ID, FIREBASE_ADMIN_CLIENT_EMAIL et FIREBASE_ADMIN_PRIVATE_KEY.',
    );
  }

  if (env.googleApplicationCredentials && !fs.existsSync(env.googleApplicationCredentials)) {
    errors.push('GOOGLE_APPLICATION_CREDENTIALS pointe vers un fichier introuvable.');
  }

  if (errors.length > 0) {
    throw new Error(`Configuration backend invalide:\n- ${errors.join('\n- ')}`);
  }

  return env;
};

export const getFirebaseAdminPrivateKey = () => env.firebaseAdminPrivateKey.replace(/\\n/g, '\n');
