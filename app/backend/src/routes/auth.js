import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { env, isBootstrapAdminEnabled } from '../config/env.js';
import { requireSuperAdminKey } from '../middlewares/requireSuperAdminKey.js';
import { hashAdminAccessKey, hashControllerCode, hashLegacySha256, matchesStoredHash } from '../services/keyHashing.js';
import { getFirebaseAdminAuth, getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { logger } from '../services/logger.js';

const router = express.Router();

export const normalizeControllerLoginCode = (value) => {
  const upper = String(value || '').trim().toUpperCase();
  return upper.startsWith('CTRL-') ? upper.substring(5) : upper;
};

const safeEquals = (left, right) => {
  const leftBuffer = Buffer.from(String(left || ''), 'utf8');
  const rightBuffer = Buffer.from(String(right || ''), 'utf8');
  if (leftBuffer.length !== rightBuffer.length) return false;
  return crypto.timingSafeEqual(leftBuffer, rightBuffer);
};

const loadControleurRecordByCode = async (code) => {
  const db = getFirebaseAdminDb();
  const codeHash = hashControllerCode(code);
  const legacyCodeHash = hashLegacySha256(code);
  const snapshot = await db
    .collection('controleurCodes')
    .where('codeHash', '==', codeHash)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    const document = snapshot.docs[0];
    return {
      id: document.id,
      ref: document.ref,
      ...document.data(),
    };
  }

  const legacyHashSnapshot = await db
    .collection('controleurCodes')
    .where('codeHash', '==', legacyCodeHash)
    .limit(1)
    .get();

  if (!legacyHashSnapshot.empty) {
    const document = legacyHashSnapshot.docs[0];
    await document.ref.set({ codeHash, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return {
      id: document.id,
      ref: document.ref,
      ...document.data(),
      codeHash,
    };
  }

  const legacySnapshot = await db
    .collection('controleurCodes')
    .where('code', '==', code)
    .limit(1)
    .get();

  if (legacySnapshot.empty) return null;
  const document = legacySnapshot.docs[0];
  return { id: document.id, ref: document.ref, ...document.data() };
};

router.post('/controller/exchange', async (req, res) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({
      message: 'Firebase Admin n\'est pas configure sur le backend.',
    });
  }

  const code = typeof req.body?.code === 'string' ? normalizeControllerLoginCode(req.body.code) : '';
  if (!code) {
    return res.status(400).json({ message: 'Le code controleur est requis.' });
  }

  try {
    const record = await loadControleurRecordByCode(code);
    if (!record) {
      return res.status(401).json({ message: 'Code controleur invalide.' });
    }

    if (record.enabled === false) {
      return res.status(403).json({ error: 'CONTROLLER_DISABLED', message: 'Ce compte controleur est desactive.' });
    }

    if (!record.usedAt) {
      await record.ref.set({
        usedAt: new Date().toISOString(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const auth = getFirebaseAdminAuth();
    const claims = {
      role: 'controller',
      controller: true,
      controleurCodeId: record.id,
      communeCode: record.commune?.code || '',
      communeId: record.commune?.code || record.commune?.name || '',
    };
    const customToken = await auth.createCustomToken(`controller:${record.id}`, claims);

    return res.json({
      customToken,
      profile: {
        id: record.id,
        label: record.label || 'Controleur',
        commune: record.commune ?? null,
      },
      claims,
    });
  } catch (error) {
    logger.error({ err: error }, 'controller_exchange_failed');
    return res.status(500).json({ message: 'Echange de code controleur impossible.' });
  }
});

router.post('/admin/exchange', async (req, res) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({
      message: 'Firebase Admin n\'est pas configure sur le backend.',
    });
  }

  const providedAccessKey = typeof req.body?.accessKey === 'string' ? req.body.accessKey.trim() : '';
  if (!providedAccessKey) {
    return res.status(400).json({ message: 'Cle administrateur requise.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const accessKeyHash = hashAdminAccessKey(providedAccessKey);
    let snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();

    if (snapshot.empty) {
      const legacySnapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', hashLegacySha256(providedAccessKey)).limit(1).get();
      if (!legacySnapshot.empty) {
        const legacyDoc = legacySnapshot.docs[0];
        await legacyDoc.ref.set({ accessKeyHash, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        snapshot = await db.collection('communeAdmins').where('accessKeyHash', '==', accessKeyHash).limit(1).get();
      }
    }

    let adminId = '';
    let communeId = '';
    let communeName = '';
    let label = 'Administrateur communal';
    let adminScope = 'commune';

    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      const data = doc.data() || {};
      if (!matchesStoredHash(providedAccessKey, data.accessKeyHash, accessKeyHash)) {
        return res.status(401).json({ message: 'Cle administrateur invalide.' });
      }
      adminId = doc.id;
      communeId = data.communeCode || data.communeName || '';
      communeName = data.communeName || '';
      label = data.label || label;
      await doc.ref.set({ lastUsedAt: FieldValue.serverTimestamp() }, { merge: true });
    } else if (env.adminAccessKey && safeEquals(providedAccessKey, env.adminAccessKey)) {
      if (!isBootstrapAdminEnabled()) {
        logger.info('bootstrap_admin_disabled');
        return res.status(403).json({ error: 'BOOTSTRAP_DISABLED', message: 'Bootstrap administrateur desactive.' });
      }
      adminId = 'bootstrap';
      adminScope = 'bootstrap';
    } else {
      return res.status(401).json({ message: 'Cle administrateur invalide.' });
    }

    const auth = getFirebaseAdminAuth();
    const claims = {
      role: 'commune_admin',
      admin: true,
      adminScope,
      communeId,
      communeCode: communeId,
    };
    const customToken = await auth.createCustomToken(`admin:${adminId}`, claims);

    return res.json({
      customToken,
      profile: { id: adminId, label, communeId, communeName },
      claims,
    });
  } catch (error) {
    logger.error({ err: error }, 'admin_token_exchange_failed');
    return res.status(500).json({ message: 'Emission du token administrateur impossible.' });
  }
});

router.post('/super/exchange', requireSuperAdminKey, async (req, res) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({
      message: 'Firebase Admin n\'est pas configure sur le backend.',
    });
  }

  try {
    const auth = getFirebaseAdminAuth();
    const customToken = await auth.createCustomToken('super:default', {
      role: 'super_admin',
      super_admin: true,
      admin: true,
      adminScope: 'global',
    });

    return res.json({
      customToken,
      claims: {
        role: 'super_admin',
        super_admin: true,
        admin: true,
        adminScope: 'global',
      },
    });
  } catch (error) {
    logger.error({ err: error }, 'super_admin_token_exchange_failed');
    return res.status(500).json({ message: 'Emission du token super administrateur impossible.' });
  }
});

export default router;