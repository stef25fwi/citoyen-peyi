import express from 'express';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { logger } from '../services/logger.js';
import { registerNotificationSubscription } from '../services/notificationService.js';
import { hashCode, normalizeCode } from './voteAccess.js';

const router = express.Router();
const ACCESS_COLLECTION = 'citizen_access_codes';

const isConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ ok: false, message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const normalizeAccessDoc = (doc) => {
  if (!doc?.exists) return null;
  const data = doc.data() || {};
  return {
    id: doc.id,
    communeId: data.communeId || '',
    communeName: data.communeName || '',
    status: data.status || 'active',
  };
};

const findAccessCode = async (db, code) => {
  const accessCodeHash = hashCode(normalizeCode(code));
  const snapshot = await db.collection(ACCESS_COLLECTION)
    .where('accessCodeHash', '==', accessCodeHash)
    .limit(1)
    .get();

  if (snapshot.empty) return null;
  return normalizeAccessDoc(snapshot.docs[0]);
};

router.use(isConfigured);

router.post('/subscribe', async (req, res) => {
  const code = normalizeCode(req.body?.code);
  const token = typeof req.body?.token === 'string' ? req.body.token.trim() : '';
  const platform = typeof req.body?.platform === 'string' ? req.body.platform.trim() : 'web';

  if (!code || !token) {
    return res.status(400).json({ ok: false, message: 'Code citoyen et token FCM requis.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const access = await findAccessCode(db, code);
    if (!access) {
      return res.status(404).json({ ok: false, message: 'Code citoyen inconnu.' });
    }
    if (['revoked', 'replaced', 'disabled', 'expired'].includes(access.status)) {
      return res.status(403).json({ ok: false, message: 'Ce code citoyen ne peut pas recevoir de notifications.' });
    }

    await registerNotificationSubscription({
      db,
      access,
      token,
      platform,
      userAgent: req.get('user-agent') || '',
    });

    return res.status(201).json({
      ok: true,
      communeId: access.communeId,
      communeName: access.communeName,
    });
  } catch (error) {
    logger.warn({ err: error }, 'notification_subscription_failed');
    return res.status(error.status || 500).json({ ok: false, message: error.message || 'Inscription aux notifications impossible.' });
  }
});

export default router;