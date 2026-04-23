import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminAuth, getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

const router = express.Router();

const normalizeCode = (value) => value.trim().toUpperCase();

const loadControleurRecordByCode = async (code) => {
  const db = getFirebaseAdminDb();
  const snapshot = await db
    .collection('controleurCodes')
    .where('code', '==', code)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return null;
  }

  const document = snapshot.docs[0];
  return {
    id: document.id,
    ref: document.ref,
    ...document.data(),
  };
};

router.post('/controller/exchange', async (req, res) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({
      message: 'Firebase Admin n\'est pas configure sur le backend.',
    });
  }

  const code = typeof req.body?.code === 'string' ? normalizeCode(req.body.code) : '';
  if (!code) {
    return res.status(400).json({ message: 'Le code controleur est requis.' });
  }

  try {
    const record = await loadControleurRecordByCode(code);
    if (!record) {
      return res.status(401).json({ message: 'Code controleur invalide.' });
    }

    if (!record.usedAt) {
      await record.ref.set({
        usedAt: new Date().toISOString(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    const auth = getFirebaseAdminAuth();
    const customToken = await auth.createCustomToken(`controller:${record.id}`, {
      role: 'controller',
      controller: true,
      controleurCodeId: record.id,
      communeCode: record.commune?.code || '',
    });

    return res.json({
      customToken,
      profile: {
        id: record.id,
        code: record.code,
        label: record.label || 'Controleur',
        commune: record.commune ?? null,
      },
      claims: {
        role: 'controller',
        controller: true,
        controleurCodeId: record.id,
        communeCode: record.commune?.code || '',
      },
    });
  } catch (error) {
    console.error('Echange de code controleur impossible.', error);
    return res.status(500).json({ message: 'Echange de code controleur impossible.' });
  }
});

router.post('/admin/exchange', async (req, res) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({
      message: 'Firebase Admin n\'est pas configure sur le backend.',
    });
  }

  const expectedAccessKey = process.env.ADMIN_ACCESS_KEY?.trim();
  const providedAccessKey = typeof req.body?.accessKey === 'string' ? req.body.accessKey.trim() : '';

  if (!expectedAccessKey) {
    return res.status(503).json({ message: 'ADMIN_ACCESS_KEY est absent sur le backend.' });
  }

  if (!providedAccessKey || providedAccessKey !== expectedAccessKey) {
    return res.status(401).json({ message: 'Cle administrateur invalide.' });
  }

  try {
    const auth = getFirebaseAdminAuth();
    const customToken = await auth.createCustomToken('admin:default', {
      role: 'admin',
      admin: true,
      adminScope: 'global',
    });

    return res.json({
      customToken,
      claims: {
        role: 'admin',
        admin: true,
        adminScope: 'global',
      },
    });
  } catch (error) {
    console.error('Emission du token administrateur impossible.', error);
    return res.status(500).json({ message: 'Emission du token administrateur impossible.' });
  }
});

export default router;