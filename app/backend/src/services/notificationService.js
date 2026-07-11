import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminMessaging } from './firebaseAdmin.js';
import { logger } from './logger.js';

export const SUBSCRIPTION_COLLECTION = 'notification_subscriptions';

export const normalizeFcmToken = (value) => (
  typeof value === 'string' ? value.trim().substring(0, 4096) : ''
);

export const notificationSubscriptionDocId = (token) => (
  crypto.createHash('sha256').update(normalizeFcmToken(token)).digest('hex')
);

const sanitizeString = (value, max) => (
  typeof value === 'string' ? value.trim().substring(0, max) : ''
);

const readDate = (value) => {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  if (value instanceof Date) return value;
  const raw = String(value).trim();
  if (!raw) return null;
  const date = new Date(raw.length === 10 ? `${raw}T00:00:00Z` : raw);
  return Number.isNaN(date.getTime()) ? null : date;
};

export const isPollVisibleForNotification = (poll, now = new Date()) => {
  const status = String(poll?.status || '').toLowerCase();
  const scheduledAt = readDate(poll?.scheduledPublishDate || poll?.publishDate);
  const scheduledIsDue = status === 'scheduled' && scheduledAt && scheduledAt <= now;
  if (!['active', 'open'].includes(status) && !scheduledIsDue) return false;

  const opensAt = readDate(poll?.opensAt || poll?.openDate);
  const closesAt = readDate(poll?.closesAt || poll?.closeDate);
  if (opensAt && opensAt > now) return false;
  if (closesAt && closesAt < now) return false;
  return true;
};

export const buildNewPollNotification = (poll) => {
  const pollId = sanitizeString(poll?.id, 128);
  const communeId = sanitizeString(poll?.communeId, 128);
  const title = sanitizeString(poll?.projectTitle || poll?.title, 120) || 'Nouvelle consultation';

  return {
    notification: {
      title: 'Nouvelle consultation Citoyen Peyi',
      body: `${title} est ouverte dans votre commune.`,
    },
    data: {
      type: 'new_poll',
      pollId,
      communeId,
      route: '/access-citizen',
    },
    webpush: {
      notification: {
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: pollId ? `poll-${pollId}` : 'citoyen-peyi-poll',
        renotify: true,
      },
    },
  };
};

export const registerNotificationSubscription = async ({
  db,
  access,
  token,
  platform = 'web',
  category = '',
  userAgent = '',
}) => {
  const normalizedToken = normalizeFcmToken(token);
  if (!normalizedToken) {
    const error = new Error('Token FCM requis.');
    error.status = 400;
    throw error;
  }

  const id = notificationSubscriptionDocId(normalizedToken);
  await db.collection(SUBSCRIPTION_COLLECTION).doc(id).set({
    id,
    token: normalizedToken,
    tokenHash: id,
    accessCodeId: access.id,
    communeId: sanitizeString(access.communeId, 128),
    communeName: sanitizeString(access.communeName, 200),
    platform: sanitizeString(platform, 40) || 'web',
    category: sanitizeString(category, 40),
    userAgent: sanitizeString(userAgent, 500),
    enabled: true,
    updatedAt: FieldValue.serverTimestamp(),
    lastRegisteredAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { id };
};

const querySubscriptions = async (db, poll) => {
  const communeId = sanitizeString(poll?.communeId, 128);
  const communeName = sanitizeString(poll?.communeName, 200);
  if (!communeId && !communeName) return [];

  const collection = db.collection(SUBSCRIPTION_COLLECTION);
  const snapshot = communeId
    ? await collection.where('communeId', '==', communeId).limit(500).get()
    : await collection.where('communeName', '==', communeName).limit(500).get();

  return snapshot.docs
    .map((doc) => ({ ref: doc.ref, id: doc.id, ...doc.data() }))
    .filter((subscription) => subscription.enabled !== false)
    .filter((subscription) => normalizeFcmToken(subscription.token));
};

const disableInvalidTokens = async (subscriptions, responses) => {
  const writes = responses
    .map((response, index) => ({ response, subscription: subscriptions[index] }))
    .filter(({ response }) => {
      const code = response.error?.code || '';
      return code === 'messaging/registration-token-not-registered' || code === 'messaging/invalid-registration-token';
    })
    .map(({ response, subscription }) => subscription.ref.set({
      enabled: false,
      disabledAt: FieldValue.serverTimestamp(),
      disabledReason: response.error?.code || 'messaging/token-invalid',
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true }));

  await Promise.allSettled(writes);
};

// ---------- Notifications push super administrateur (tickets assistance) ----------

export const SUPER_ADMIN_SUBSCRIPTION_COLLECTION = 'super_admin_push_subscriptions';

export const registerSuperAdminSubscription = async ({
  db,
  token,
  uid = '',
  platform = 'web',
  userAgent = '',
}) => {
  const normalizedToken = normalizeFcmToken(token);
  if (!normalizedToken) {
    const error = new Error('Token FCM requis.');
    error.status = 400;
    throw error;
  }

  const id = notificationSubscriptionDocId(normalizedToken);
  await db.collection(SUPER_ADMIN_SUBSCRIPTION_COLLECTION).doc(id).set({
    id,
    token: normalizedToken,
    tokenHash: id,
    uid: sanitizeString(uid, 128),
    platform: sanitizeString(platform, 40) || 'web',
    userAgent: sanitizeString(userAgent, 500),
    enabled: true,
    updatedAt: FieldValue.serverTimestamp(),
    lastRegisteredAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { id };
};

export const buildNewTicketNotification = (ticket) => {
  const ticketId = sanitizeString(ticket?.ticketId, 128);
  const communeName = sanitizeString(ticket?.communeName, 200) || 'une commune';
  const subject = sanitizeString(ticket?.subject, 120) || 'Nouveau ticket';
  const priority = sanitizeString(ticket?.priority, 20);
  const urgentPrefix = priority === 'urgente' ? '[URGENT] ' : '';

  return {
    notification: {
      title: `${urgentPrefix}Nouveau ticket assistance`,
      body: `${communeName} : ${subject}`,
    },
    data: {
      type: 'new_support_ticket',
      ticketId,
      route: '/super-admin/support',
    },
    webpush: {
      notification: {
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        tag: ticketId ? `ticket-${ticketId}` : 'citoyen-peyi-ticket',
        renotify: true,
      },
      fcmOptions: {
        link: '/#/super-admin/support',
      },
    },
  };
};

const querySuperAdminSubscriptions = async (db) => {
  const snapshot = await db.collection(SUPER_ADMIN_SUBSCRIPTION_COLLECTION).limit(500).get();
  return snapshot.docs
    .map((doc) => ({ ref: doc.ref, id: doc.id, ...doc.data() }))
    .filter((subscription) => subscription.enabled !== false)
    .filter((subscription) => normalizeFcmToken(subscription.token));
};

export const notifySuperAdminsNewTicket = async ({ db, ticket }) => {
  try {
    const subscriptions = await querySuperAdminSubscriptions(db);
    if (subscriptions.length === 0) {
      return { attempted: 0, sent: 0, failed: 0 };
    }

    const message = buildNewTicketNotification(ticket);
    const messaging = getFirebaseAdminMessaging();
    let sent = 0;
    let failed = 0;

    for (let index = 0; index < subscriptions.length; index += 500) {
      const chunk = subscriptions.slice(index, index + 500);
      const response = await messaging.sendEachForMulticast({
        ...message,
        tokens: chunk.map((subscription) => subscription.token),
      });
      sent += response.successCount;
      failed += response.failureCount;
      await disableInvalidTokens(chunk, response.responses);
    }

    logger.info({
      ticketId: ticket?.ticketId,
      attempted: subscriptions.length,
      sent,
      failed,
    }, 'ticket_push_notifications_sent');
    return { attempted: subscriptions.length, sent, failed };
  } catch (error) {
    logger.warn({ err: error, ticketId: ticket?.ticketId }, 'ticket_push_notification_failed');
    return { attempted: 0, sent: 0, failed: 0 };
  }
};

export const notifyCommunePollPublished = async ({ db, poll }) => {
  if (!isPollVisibleForNotification(poll)) {
    return { attempted: 0, sent: 0, failed: 0 };
  }

  try {
    const subscriptions = await querySubscriptions(db, poll);
    if (subscriptions.length === 0) {
      return { attempted: 0, sent: 0, failed: 0 };
    }

    const message = buildNewPollNotification(poll);
    const messaging = getFirebaseAdminMessaging();
    let sent = 0;
    let failed = 0;

    for (let index = 0; index < subscriptions.length; index += 500) {
      const chunk = subscriptions.slice(index, index + 500);
      const response = await messaging.sendEachForMulticast({
        ...message,
        tokens: chunk.map((subscription) => subscription.token),
      });
      sent += response.successCount;
      failed += response.failureCount;
      await disableInvalidTokens(chunk, response.responses);
    }

    logger.info({
      pollId: poll.id,
      communeId: poll.communeId,
      attempted: subscriptions.length,
      sent,
      failed,
    }, 'poll_push_notifications_sent');
    return { attempted: subscriptions.length, sent, failed };
  } catch (error) {
    logger.warn({ err: error, pollId: poll?.id }, 'poll_push_notification_failed');
    return { attempted: 0, sent: 0, failed: 0 };
  }
};