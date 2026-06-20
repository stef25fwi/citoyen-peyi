import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import authRoutes from './routes/auth.js';
import citizenAccessRoutes from './routes/citizenAccess.js';
import voteAccessRoutes from './routes/voteAccess.js';
import pollRoutes from './routes/polls.js';
import pollAiRoutes from './routes/pollAi.js';
import newsRoutes from './routes/news.js';
import adminRoutes from './routes/admins.js';
import controllerRoutes from './routes/controllers.js';
import notificationRoutes from './routes/notifications.js';
import supportRoutes from './routes/support.js';
import backupRoutes from './routes/backups.js';
import { env, isFirebaseAdminConfigured, isSuperAdminConfigured, validateEnv } from './config/env.js';
import { logger, httpLogger } from './services/logger.js';
import { errorHandler, notFoundHandler, registerProcessHandlers } from './middlewares/errorHandler.js';
import { authRateLimiter, voteAccessRateLimiter, writeRateLimiter } from './middlewares/rateLimit.js';
import { getFirebaseAdminDb } from './services/firebaseAdmin.js';

validateEnv();
registerProcessHandlers();

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);

app.use(httpLogger);
// API consommee en cross-origin (web.app / github.io -> Cloud Run). Le defaut
// helmet "Cross-Origin-Resource-Policy: same-origin" fait que Safari bloque la
// lecture des reponses cross-origin (fetch -> TypeError). On autorise cross-origin.
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));
app.use(cors({
  origin: env.corsOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-super-admin-key'],
  maxAge: 86400,
}));
app.use(express.json({ limit: '100kb' }));

// Garde-fou: limite la duree maximale d'une requete pour eviter les sockets bloques.
app.use((req, res, next) => {
  res.setTimeout(30000, () => {
    if (!res.headersSent) {
      res.status(503).json({ message: 'Requete trop longue, reessayez.' });
    }
  });
  next();
});

app.get('/api/health/live', (_req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

app.get('/api/health/ready', async (_req, res) => {
  const checks = {
    superAdminConfigured: isSuperAdminConfigured(),
    firebaseAdminConfigured: isFirebaseAdminConfigured(),
    firestoreReachable: false,
  };

  if (checks.firebaseAdminConfigured) {
    try {
      await getFirebaseAdminDb().listCollections();
      checks.firestoreReachable = true;
    } catch (error) {
      logger.warn({ err: error }, 'firestore_ready_check_failed');
    }
  }

  const ok = Object.values(checks).every(Boolean);
  res.status(ok ? 200 : 503).json({ ok, checks, time: new Date().toISOString() });
});

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'citoyen-peyi-backend',
    firebaseAdminConfigured: isFirebaseAdminConfigured(),
    superAdminConfigured: isSuperAdminConfigured(),
    time: new Date().toISOString(),
  });
});

app.use('/api/auth', authRateLimiter, authRoutes);
app.use('/api/citizen-access', writeRateLimiter, citizenAccessRoutes);
app.use('/api/vote-access', voteAccessRateLimiter, voteAccessRoutes);
app.use('/api/polls', writeRateLimiter, pollRoutes);
app.use('/api/poll-ai', writeRateLimiter, pollAiRoutes);
app.use('/api/news', writeRateLimiter, newsRoutes);
app.use('/api/notifications', voteAccessRateLimiter, notificationRoutes);
app.use('/api/admins', writeRateLimiter, adminRoutes);
app.use('/api/controllers', writeRateLimiter, controllerRoutes);
app.use('/api/support', writeRateLimiter, supportRoutes);
app.use('/api/backups', writeRateLimiter, backupRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

const server = app.listen(env.port, () => {
  logger.info({ port: env.port, env: env.nodeEnv }, 'api_listening');
});

const shutdown = (signal) => {
  logger.info({ signal }, 'shutdown_requested');
  server.close(() => {
    logger.info('http_server_closed');
    process.exit(0);
  });
  setTimeout(() => process.exit(1), 10000).unref();
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
