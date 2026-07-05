import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import {
  communeScopeFromUser,
  isCommuneAdmin,
  isSuperAdmin,
  requireCommuneAdmin,
  requireCommuneScope,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';
import { notifySuperAdminsNewTicket, registerSuperAdminSubscription } from '../services/notificationService.js';
import { logger } from '../services/logger.js';

const router = express.Router();
const TICKET_COLLECTION = 'support_tickets';

const categories = new Set([
  'Problème de connexion',
  'Problème de consultation',
  'Problème de code citoyen',
  'Problème de vote',
  'Demande de modification',
  'Demande de formation',
  'Problème technique',
  'Autre',
]);

const priorities = new Set(['faible', 'normale', 'urgente']);
const statuses = new Set(['ouvert', 'en_cours', 'en_attente_admin', 'resolu', 'ferme']);

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');

const toIso = (value) => {
  if (!value) return '';
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return String(value);
};

const statusMessage = (status) => {
  switch (status) {
    case 'en_cours':
      return 'Le ticket est passé au statut : En cours.';
    case 'en_attente_admin':
      return 'Le ticket est passé au statut : En attente admin.';
    case 'resolu':
      return 'Le ticket est passé au statut : Résolu.';
    case 'ferme':
      return 'Le ticket a été clôturé par le super administrateur.';
    case 'ouvert':
      return 'Le ticket a été rouvert.';
    default:
      return 'Le statut du ticket a été mis à jour.';
  }
};

const serializeTicket = (docOrData) => {
  const id = docOrData.id || docOrData.ticketId || '';
  const data = typeof docOrData.data === 'function' ? docOrData.data() || {} : docOrData;
  return {
    ticketId: data.ticketId || id,
    communeId: data.communeId || '',
    communeName: data.communeName || '',
    createdByUserId: data.createdByUserId || '',
    createdByName: data.createdByName || '',
    createdByEmail: data.createdByEmail || '',
    createdByRole: data.createdByRole || 'admin_communal',
    assignedToRole: data.assignedToRole || 'super_admin',
    subject: data.subject || '',
    category: data.category || '',
    priority: data.priority || 'normale',
    status: data.status || 'ouvert',
    lastMessage: data.lastMessage || '',
    lastMessageByRole: data.lastMessageByRole || '',
    messagesCount: Number(data.messagesCount || 0),
    unreadForSuperAdmin: data.unreadForSuperAdmin === true,
    unreadForAdmin: data.unreadForAdmin === true,
    createdAt: toIso(data.createdAt),
    updatedAt: toIso(data.updatedAt),
    closedAt: data.closedAt ? toIso(data.closedAt) : null,
    closedBy: data.closedBy || null,
  };
};

const serializeMessage = (docOrData) => {
  const id = docOrData.id || docOrData.messageId || '';
  const data = typeof docOrData.data === 'function' ? docOrData.data() || {} : docOrData;
  return {
    messageId: data.messageId || id,
    ticketId: data.ticketId || '',
    senderId: data.senderId || '',
    senderName: data.senderName || '',
    senderEmail: data.senderEmail || '',
    senderRole: data.senderRole || 'system',
    message: data.message || '',
    createdAt: toIso(data.createdAt),
    isInternal: data.isInternal !== false,
    readBySuperAdmin: data.readBySuperAdmin === true,
    readByAdmin: data.readByAdmin === true,
  };
};

const sortTickets = (tickets) => tickets.sort((left, right) => {
  const urgent = (right.priority === 'urgente' ? 1 : 0) - (left.priority === 'urgente' ? 1 : 0);
  if (urgent !== 0) return urgent;
  return String(right.updatedAt || '').localeCompare(String(left.updatedAt || ''));
});

const requireAdminCommuneScope = (req, res) => {
  const scope = communeScopeFromUser(req.user);
  if (!scope) {
    res.status(403).json({ message: 'Aucune commune attachée au compte administrateur.' });
    return null;
  }
  return scope;
};

const canAccessTicket = (user, ticket) => {
  if (isSuperAdmin(user)) return true;
  if (!isCommuneAdmin(user)) return false;
  const scope = communeScopeFromUser(user);
  return Boolean(scope && ticket.communeId === scope);
};

const loadTicketForAccess = async (req, res) => {
  const db = getFirebaseAdminDb();
  const ref = db.collection(TICKET_COLLECTION).doc(req.params.ticketId);
  const doc = await ref.get();
  if (!doc.exists) {
    res.status(404).json({ message: 'Ticket introuvable.' });
    return null;
  }
  const ticket = serializeTicket(doc);
  if (!canAccessTicket(req.user, ticket)) {
    res.status(403).json({ message: 'Accès refusé à ce ticket.' });
    return null;
  }
  return { ref, ticket };
};

const messagePayload = ({ messageRef, ticketId, senderId, senderName, senderEmail, senderRole, message, readBySuperAdmin, readByAdmin, timestamp }) => ({
  messageId: messageRef.id,
  ticketId,
  senderId,
  senderName,
  senderEmail,
  senderRole,
  message,
  createdAt: timestamp,
  isInternal: true,
  readBySuperAdmin,
  readByAdmin,
});

router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin, requireCommuneScope);

router.get('/tickets', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    let query = db.collection(TICKET_COLLECTION);
    if (!isSuperAdmin(req.user)) {
      const scope = requireAdminCommuneScope(req, res);
      if (!scope) return undefined;
      query = query.where('communeId', '==', scope);
    }
    const snapshot = await query.limit(500).get();
    return res.json({ tickets: sortTickets(snapshot.docs.map(serializeTicket)) });
  } catch (error) {
    return next(error);
  }
});

router.post('/tickets', async (req, res, next) => {
  try {
    if (isSuperAdmin(req.user)) {
      return res.status(403).json({ message: 'La création de ticket est réservée aux administrateurs communaux.' });
    }
    const communeId = requireAdminCommuneScope(req, res);
    if (!communeId) return undefined;

    const subject = sanitize(req.body?.subject, 200);
    const category = sanitize(req.body?.category, 80);
    const priority = sanitize(req.body?.priority, 20);
    const message = sanitize(req.body?.message, 5000);
    const communeName = sanitize(req.body?.communeName, 200) || communeId;
    const createdByName = sanitize(req.body?.createdByName, 200) || 'Administrateur communal';
    const createdByEmail = sanitize(req.body?.createdByEmail, 200);

    if (subject.length < 5) return res.status(400).json({ message: 'Le sujet doit contenir au moins 5 caractères.' });
    if (!categories.has(category)) return res.status(400).json({ message: 'Catégorie obligatoire.' });
    if (!priorities.has(priority)) return res.status(400).json({ message: 'Priorité obligatoire.' });
    if (message.length < 10) return res.status(400).json({ message: 'Le message doit contenir au moins 10 caractères.' });

    const db = getFirebaseAdminDb();
    const ticketRef = db.collection(TICKET_COLLECTION).doc();
    const messageRef = ticketRef.collection('messages').doc();
    const timestamp = FieldValue.serverTimestamp();
    const senderId = req.user?.uid || 'admin_communal';

    const ticket = {
      ticketId: ticketRef.id,
      communeId,
      communeName,
      createdByUserId: senderId,
      createdByName,
      createdByEmail,
      createdByRole: 'admin_communal',
      assignedToRole: 'super_admin',
      subject,
      category,
      priority,
      status: 'ouvert',
      lastMessage: message,
      lastMessageByRole: 'admin_communal',
      messagesCount: 1,
      unreadForSuperAdmin: true,
      unreadForAdmin: false,
      createdAt: timestamp,
      updatedAt: timestamp,
      closedAt: null,
      closedBy: null,
    };

    const batch = db.batch();
    batch.set(ticketRef, ticket);
    batch.set(messageRef, messagePayload({
      messageRef,
      ticketId: ticketRef.id,
      senderId,
      senderName: createdByName,
      senderEmail: createdByEmail,
      senderRole: 'admin_communal',
      message,
      readBySuperAdmin: false,
      readByAdmin: true,
      timestamp,
    }));
    await batch.commit();

    // Notification push aux super administrateurs abonnes (best-effort, ne
    // bloque jamais la creation du ticket).
    await notifySuperAdminsNewTicket({
      db,
      ticket: {
        ticketId: ticketRef.id,
        communeName,
        subject,
        priority,
      },
    });

    return res.status(201).json({ ok: true, ticketId: ticketRef.id });
  } catch (error) {
    return next(error);
  }
});

// Abonnement push du super administrateur (token FCM de son navigateur/app).
router.post('/subscribe', async (req, res, next) => {
  try {
    if (!isSuperAdmin(req.user)) {
      return res.status(403).json({ message: 'Reserve au super administrateur.' });
    }
    const token = sanitize(req.body?.token, 4096);
    const platform = sanitize(req.body?.platform, 40) || 'web';
    if (!token) {
      return res.status(400).json({ message: 'Token FCM requis.' });
    }

    const db = getFirebaseAdminDb();
    await registerSuperAdminSubscription({
      db,
      token,
      uid: req.user?.uid || '',
      platform,
      userAgent: req.get('user-agent') || '',
    });
    return res.status(201).json({ ok: true });
  } catch (error) {
    logger.warn({ err: error }, 'super_admin_subscription_failed');
    return next(error);
  }
});

router.get('/tickets/:ticketId', async (req, res, next) => {
  try {
    const loaded = await loadTicketForAccess(req, res);
    if (!loaded) return undefined;
    return res.json({ ticket: loaded.ticket });
  } catch (error) {
    return next(error);
  }
});

router.get('/tickets/:ticketId/messages', async (req, res, next) => {
  try {
    const loaded = await loadTicketForAccess(req, res);
    if (!loaded) return undefined;
    const snapshot = await loaded.ref.collection('messages').orderBy('createdAt').limit(500).get();
    return res.json({ messages: snapshot.docs.map(serializeMessage) });
  } catch (error) {
    return next(error);
  }
});

router.post('/tickets/:ticketId/messages', async (req, res, next) => {
  try {
    const normalizedMessage = sanitize(req.body?.message, 5000);
    if (normalizedMessage.length < 2) {
      return res.status(400).json({ message: 'Le message doit contenir au moins 2 caractères.' });
    }

    const loaded = await loadTicketForAccess(req, res);
    if (!loaded) return undefined;
    if (loaded.ticket.status === 'ferme') {
      return res.status(409).json({ message: 'Ce ticket est fermé. Rouvrez-le avant de répondre.' });
    }

    const db = getFirebaseAdminDb();
    await db.runTransaction(async (transaction) => {
      const ticketDoc = await transaction.get(loaded.ref);
      if (!ticketDoc.exists) {
        const error = new Error('Ticket introuvable.');
        error.status = 404;
        throw error;
      }
      const freshTicket = serializeTicket(ticketDoc);
      if (!canAccessTicket(req.user, freshTicket)) {
        const error = new Error('Accès refusé à ce ticket.');
        error.status = 403;
        throw error;
      }
      if (freshTicket.status === 'ferme') {
        const error = new Error('Ce ticket est fermé. Rouvrez-le avant de répondre.');
        error.status = 409;
        throw error;
      }

      const timestamp = FieldValue.serverTimestamp();
      const isReplyFromSuperAdmin = isSuperAdmin(req.user);
      const role = isReplyFromSuperAdmin ? 'super_admin' : 'admin_communal';
      const senderName = sanitize(req.body?.senderName, 200) || (isReplyFromSuperAdmin ? 'Super administrateur' : 'Administrateur communal');
      const senderEmail = sanitize(req.body?.senderEmail, 200);
      const messageRef = loaded.ref.collection('messages').doc();
      const movesToInProgress = isReplyFromSuperAdmin && freshTicket.status === 'ouvert';
      const systemMessageRef = movesToInProgress ? loaded.ref.collection('messages').doc() : null;

      transaction.set(messageRef, messagePayload({
        messageRef,
        ticketId: loaded.ticket.ticketId,
        senderId: req.user?.uid || role,
        senderName,
        senderEmail,
        senderRole: role,
        message: normalizedMessage,
        readBySuperAdmin: isReplyFromSuperAdmin,
        readByAdmin: !isReplyFromSuperAdmin,
        timestamp,
      }));

      if (systemMessageRef) {
        transaction.set(systemMessageRef, messagePayload({
          messageRef: systemMessageRef,
          ticketId: loaded.ticket.ticketId,
          senderId: req.user?.uid || 'super_admin',
          senderName: 'Système',
          senderEmail: '',
          senderRole: 'system',
          message: statusMessage('en_cours'),
          readBySuperAdmin: true,
          readByAdmin: false,
          timestamp,
        }));
      }

      transaction.update(loaded.ref, {
        lastMessage: normalizedMessage,
        lastMessageByRole: role,
        messagesCount: FieldValue.increment(movesToInProgress ? 2 : 1),
        updatedAt: timestamp,
        unreadForSuperAdmin: !isReplyFromSuperAdmin,
        unreadForAdmin: isReplyFromSuperAdmin,
        ...(movesToInProgress ? { status: 'en_cours' } : {}),
      });
    });

    return res.status(201).json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

router.patch('/tickets/:ticketId/status', async (req, res, next) => {
  try {
    if (!isSuperAdmin(req.user)) {
      return res.status(403).json({ message: 'Réservé au super administrateur.' });
    }
    const status = sanitize(req.body?.status, 32);
    if (!statuses.has(status)) return res.status(400).json({ message: 'Statut invalide.' });

    const loaded = await loadTicketForAccess(req, res);
    if (!loaded) return undefined;
    const db = getFirebaseAdminDb();

    await db.runTransaction(async (transaction) => {
      const ticketDoc = await transaction.get(loaded.ref);
      if (!ticketDoc.exists) {
        const error = new Error('Ticket introuvable.');
        error.status = 404;
        throw error;
      }
      const timestamp = FieldValue.serverTimestamp();
      const message = statusMessage(status);
      const messageRef = loaded.ref.collection('messages').doc();
      transaction.set(messageRef, messagePayload({
        messageRef,
        ticketId: loaded.ticket.ticketId,
        senderId: req.user?.uid || 'super_admin',
        senderName: 'Système',
        senderEmail: '',
        senderRole: 'system',
        message,
        readBySuperAdmin: true,
        readByAdmin: false,
        timestamp,
      }));
      transaction.update(loaded.ref, {
        status,
        lastMessage: message,
        lastMessageByRole: 'system',
        messagesCount: FieldValue.increment(1),
        updatedAt: timestamp,
        unreadForSuperAdmin: false,
        unreadForAdmin: true,
        closedAt: status === 'ferme' ? timestamp : null,
        closedBy: status === 'ferme' ? req.user?.uid || 'super_admin' : null,
      });
    });

    return res.json({ ok: true, status });
  } catch (error) {
    return next(error);
  }
});

router.post('/tickets/:ticketId/read', async (req, res, next) => {
  try {
    const loaded = await loadTicketForAccess(req, res);
    if (!loaded) return undefined;
    await loaded.ref.set({
      ...(isSuperAdmin(req.user) ? { unreadForSuperAdmin: false } : { unreadForAdmin: false }),
    }, { merge: true });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
export { canAccessTicket, serializeMessage, serializeTicket, sortTickets, statusMessage };
