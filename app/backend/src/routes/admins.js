import express from 'express';
import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminAuth, getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { requireFirebaseAuth, requireSuperAdmin } from '../middlewares/requireFirebaseAuth.js';
import { hashAdminAccessKey } from '../services/keyHashing.js';
import { resolveCanonicalCommune } from '../services/communeDirectory.js';
import { archiveDeletedRecord } from '../services/deletionArchive.js';

const router = express.Router();
const COLLECTION = 'communeAdmins';
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');
const normalizeIds = (raw) => (Array.isArray(raw) ? raw : [])
  .map((value) => sanitize(value, 128))
  .filter(Boolean)
  .slice(0, 100);

export const generateAccessKey = () => {
  const buf = crypto.randomBytes(16);
  const part1 = Array.from(buf.slice(0, 8)).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
  const part2 = Array.from(buf.slice(8, 12)).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
  return `ADM-${part1}-${part2}`;
};

// E-mail de reference (optionnel) : normalise + valide grossierement. Renvoie ''
// si vide ou format invalide.
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
export const normalizeEmail = (value) => {
  const email = sanitize(value, 200).toLowerCase();
  return email && EMAIL_PATTERN.test(email) ? email : '';
};

router.use(ensureConfigured, requireFirebaseAuth, requireSuperAdmin);

router.get('/', async (_req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const snapshot = await db.collection(COLLECTION).limit(500).get();
    res.json({
      admins: snapshot.docs.map((doc) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          label: data.label,
          communeName: data.communeName,
          communeCode: data.communeCode,
          codePostal: data.codePostal,
          referenceEmail: data.referenceEmail || '',
          createdAt: data.createdAt,
          lastUsedAt: data.lastUsedAt,
        };
      }),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const label = sanitize(req.body?.label, 200);
    const inputCommuneName = sanitize(req.body?.communeName, 200);
    const communeCode = sanitize(req.body?.communeCode, 64);
    const inputCodePostal = sanitize(req.body?.codePostal, 16);
    const rawEmail = sanitize(req.body?.referenceEmail, 200);
    const referenceEmail = normalizeEmail(rawEmail);

    if (!label || !inputCommuneName) {
      return res.status(400).json({ message: 'Libelle et commune sont requis.' });
    }
    // E-mail optionnel : s'il est fourni mais mal forme, on refuse plutot que
    // d'enregistrer une adresse inexploitable.
    if (rawEmail && !referenceEmail) {
      return res.status(400).json({ message: 'E-mail de reference invalide.' });
    }

    const db = getFirebaseAdminDb();

    // Consolidation : si un admin existe deja pour ce code INSEE, on reprend
    // l'identite canonique de la commune (nom + code postal) pour rattacher le
    // nouveau compte a la commune existante plutot que d'en creer une variante.
    const commune = await resolveCanonicalCommune(db, {
      communeCode,
      communeName: inputCommuneName,
      codePostal: inputCodePostal,
    });

    const accessKey = generateAccessKey();
    const id = `adm-${crypto.randomBytes(8).toString('hex')}`;

    await db.collection(COLLECTION).doc(id).set({
      id,
      label,
      communeName: commune.communeName,
      communeCode: commune.communeCode,
      codePostal: commune.codePostal,
      referenceEmail,
      accessKeyHash: hashAdminAccessKey(accessKey),
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user?.uid || 'super_admin',
    });

    return res.status(201).json({
      id,
      label,
      communeName: commune.communeName,
      communeCode: commune.communeCode,
      codePostal: commune.codePostal,
      referenceEmail,
      accessKey,
      attachedToExistingCommune: commune.matched,
    });
  } catch (error) {
    return next(error);
  }
});

router.post('/bulk-delete', async (req, res, next) => {
  try {
    const ids = normalizeIds(req.body?.ids);
    if (ids.length === 0) return res.status(400).json({ message: 'Aucun profil selectionne.' });

    const db = getFirebaseAdminDb();
    let deleted = 0;
    const missing = [];

    for (const id of ids) {
      const ref = db.collection(COLLECTION).doc(id);
      const doc = await ref.get();
      if (!doc.exists) {
        missing.push(id);
        continue;
      }
      await archiveDeletedRecord(db, {
        kind: 'commune_admin',
        sourceCollection: COLLECTION,
        recordId: id,
        data: { id: doc.id, ...doc.data() },
        deletedBy: req.user?.uid || 'super_admin',
        reason: 'bulk_delete',
      });
      await ref.delete();
      deleted += 1;
      try {
        await getFirebaseAdminAuth().revokeRefreshTokens(`admin:${id}`);
      } catch (_) {
        // L'utilisateur Firebase peut ne jamais avoir ete cree : ignore.
      }
    }

    return res.json({ ok: true, deleted, missing });
  } catch (error) {
    return next(error);
  }
});

// Regenere la cle d'acces d'un admin communal. Les cles sont hachees (jamais
// stockees en clair) : l'originale est irrecuperable, on en emet donc une
// nouvelle (affichee une seule fois) et l'ancienne est invalidee.
router.post('/:adminId/regenerate', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const ref = db.collection(COLLECTION).doc(req.params.adminId);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Profil introuvable.' });

    const accessKey = generateAccessKey();
    await ref.set({
      accessKeyHash: hashAdminAccessKey(accessKey),
      keyRegeneratedAt: FieldValue.serverTimestamp(),
      keyRegeneratedBy: req.user?.uid || 'super_admin',
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // Invalide les sessions Firebase eventuellement actives pour cet admin.
    try {
      await getFirebaseAdminAuth().revokeRefreshTokens(`admin:${req.params.adminId}`);
    } catch (_) {
      // L'utilisateur Firebase peut ne jamais avoir ete cree : ignore.
    }

    const data = doc.data() || {};
    return res.json({
      id: doc.id,
      label: data.label,
      communeName: data.communeName,
      communeCode: data.communeCode,
      codePostal: data.codePostal,
      referenceEmail: data.referenceEmail || '',
      accessKey,
    });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:adminId', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const ref = db.collection(COLLECTION).doc(req.params.adminId);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Profil introuvable.' });
    await archiveDeletedRecord(db, {
      kind: 'commune_admin',
      sourceCollection: COLLECTION,
      recordId: doc.id,
      data: { id: doc.id, ...doc.data() },
      deletedBy: req.user?.uid || 'super_admin',
      reason: 'manual_delete',
    });
    await ref.delete();
    try {
      await getFirebaseAdminAuth().revokeRefreshTokens(`admin:${req.params.adminId}`);
    } catch (_) {
      // L'utilisateur Firebase peut ne jamais avoir ete cree : ignore.
    }
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
