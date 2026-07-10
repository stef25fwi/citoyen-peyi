import { env } from '../config/env.js';
import { getFirebaseAdminAppCheck } from '../services/firebaseAdmin.js';

export const requireAppCheck = async (req, res, next) => {
  if (!env.appCheckEnforced) return next();

  const token = typeof req.headers['x-firebase-appcheck'] === 'string'
    ? req.headers['x-firebase-appcheck'].trim()
    : '';

  if (!token) {
    return res.status(401).json({
      ok: false,
      errorCode: 'APP_CHECK_REQUIRED',
      message: 'Attestation App Check requise.',
    });
  }

  try {
    req.appCheck = await getFirebaseAdminAppCheck().verifyToken(token);
    return next();
  } catch (_error) {
    return res.status(401).json({
      ok: false,
      errorCode: 'APP_CHECK_INVALID',
      message: 'Attestation App Check invalide ou expirée.',
    });
  }
};