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

const parseCorsOrigins = (value, { nodeEnv } = {}) => {
  const configured = String(value || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (configured.length > 0) return configured;
  if (nodeEnv === 'production') return [];
  return defaultCorsOrigins;
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

const nodeEnv = optional(process.env.NODE_ENV) || 'development';

export const env = {
  nodeEnv,
  isProduction: nodeEnv === 'production',
  port: Number(process.env.PORT || 4000),
  apiBaseUrl: optional(process.env.API_BASE_URL),
  corsOrigins: parseCorsOrigins(process.env.CORS_ORIGIN, { nodeEnv }),
  logLevel: optional(process.env.LOG_LEVEL) || (nodeEnv === 'production' ? 'info' : 'debug'),
  superAdminKey: optional(process.env.SUPER_ADMIN_KEY),
  adminAccessKey: optional(process.env.ADMIN_ACCESS_KEY),
  enableBootstrapAdmin: optional(process.env.ENABLE_BOOTSTRAP_ADMIN) === 'true',
  accessCodePepper: optional(process.env.ACCESS_CODE_PEPPER),
  citizenFingerprintPepper: optional(process.env.CITIZEN_FINGERPRINT_PEPPER),
  voteAccessTokenSecret: optional(process.env.VOTE_ACCESS_TOKEN_SECRET),
  googleApplicationCredentials: optional(process.env.GOOGLE_APPLICATION_CREDENTIALS),
  firebaseAdminProjectId: optional(process.env.FIREBASE_ADMIN_PROJECT_ID),
  firebaseAdminClientEmail: optional(process.env.FIREBASE_ADMIN_CLIENT_EMAIL),
  firebaseAdminPrivateKey: optional(process.env.FIREBASE_ADMIN_PRIVATE_KEY),
};

export const isSuperAdminConfigured = () => Boolean(env.superAdminKey);

export const isBootstrapAdminEnabled = () => env.enableBootstrapAdmin;


export const isFirebaseAdminConfigured = () => Boolean(
  env.googleApplicationCredentials ||
  (
    env.firebaseAdminProjectId &&
    env.firebaseAdminClientEmail &&
    env.firebaseAdminPrivateKey
  ) ||
  (
    process.env.K_SERVICE &&
    (
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT ||
      process.env.FIREBASE_PROJECT_ID
    )
  )
);

export const validateEnv = () => {
  const errors = [];

  if (!isSuperAdminConfigured()) {
    errors.push('SUPER_ADMIN_KEY est requis pour proteger les routes super administrateur.');
  }

  if (env.isProduction && env.superAdminKey.length < 32) {
    errors.push('SUPER_ADMIN_KEY doit faire au moins 32 caracteres en production.');
  }

  if (!isFirebaseAdminConfigured()) {
    errors.push(
      'Firebase Admin doit etre configure avec GOOGLE_APPLICATION_CREDENTIALS pointant vers un fichier existant, ou avec FIREBASE_ADMIN_PROJECT_ID, FIREBASE_ADMIN_CLIENT_EMAIL et FIREBASE_ADMIN_PRIVATE_KEY.',
    );
  }

  if (!env.voteAccessTokenSecret) {
    errors.push('VOTE_ACCESS_TOKEN_SECRET est requis pour signer les tokens temporaires de vote.');
  }

  if (env.isProduction && env.voteAccessTokenSecret.length < 32) {
    errors.push('VOTE_ACCESS_TOKEN_SECRET doit faire au moins 32 caracteres en production.');
  }

  if (env.isProduction && !env.accessCodePepper) {
    errors.push('ACCESS_CODE_PEPPER est requis en production pour hacher les codes citoyens.');
  }

  if (env.isProduction && !env.citizenFingerprintPepper) {
    errors.push('CITIZEN_FINGERPRINT_PEPPER est requis en production pour hacher les empreintes citoyennes.');
  }

  if (env.isProduction && env.accessCodePepper && env.accessCodePepper.length < 32) {
    errors.push('ACCESS_CODE_PEPPER doit faire au moins 32 caracteres en production.');
  }

  if (env.isProduction && env.citizenFingerprintPepper && env.citizenFingerprintPepper.length < 32) {
    errors.push('CITIZEN_FINGERPRINT_PEPPER doit faire au moins 32 caracteres en production.');
  }

  if (env.isProduction && env.corsOrigins.length === 0) {
    errors.push('CORS_ORIGIN doit etre defini explicitement en production (au moins un domaine HTTPS).');
  }

  if (env.isProduction) {
    const insecureOrigins = env.corsOrigins.filter((origin) => /^http:\/\/(localhost|127\.|0\.0\.0\.0)/i.test(origin));
    if (insecureOrigins.length > 0) {
      errors.push(`CORS_ORIGIN contient des origines de developpement en production: ${insecureOrigins.join(', ')}`);
    }
  }

  if (env.googleApplicationCredentials && !fs.existsSync(env.googleApplicationCredentials)) {
    errors.push('GOOGLE_APPLICATION_CREDENTIALS pointe vers un fichier introuvable.');
  }

  if (errors.length > 0) {
    
  const hasCloudRunApplicationDefaultCredentials = Boolean(
    process.env.K_SERVICE &&
    (
      process.env.GOOGLE_CLOUD_PROJECT ||
      process.env.GCLOUD_PROJECT ||
      process.env.FIREBASE_PROJECT_ID
    )
  );

  if (hasCloudRunApplicationDefaultCredentials) {
    for (let index = errors.length - 1; index >= 0; index -= 1) {
      if (String(errors[index]).includes('Firebase Admin doit etre configure')) {
        errors.splice(index, 1);
      }
    }
  }


  for (let index = errors.length - 1; index >= 0; index -= 1) {
    if (!String(errors[index] ?? '').trim()) {
      errors.splice(index, 1);
    }
  }

if (errors.length > 0) {
    throw new Error(`Configuration backend invalide:\n- ${errors.join('\n- ')}`);
  }
  }

  return env;
};

export const getFirebaseAdminPrivateKey = () => env.firebaseAdminPrivateKey.replace(/\\n/g, '\n');
