import express from 'express';
import cors from 'cors';
import voteRoutes from './routes/votes.js';
import authRoutes from './routes/auth.js';
import citizenAccessRoutes from './routes/citizenAccess.js';
import { env, isFirebaseAdminConfigured, isSuperAdminConfigured, validateEnv } from './config/env.js';

validateEnv();

const app = express();
const port = env.port;

app.use(cors({ origin: env.corsOrigins }));
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({
    ok: true,
    service: 'citoyen-peyi-backend',
    firebaseAdminConfigured: isFirebaseAdminConfigured(),
    superAdminConfigured: isSuperAdminConfigured(),
    time: new Date().toISOString(),
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/votes', voteRoutes);
app.use('/api/citizen-access', citizenAccessRoutes);

app.listen(port, () => {
  console.log(`API en ecoute sur le port ${port}`);
});
