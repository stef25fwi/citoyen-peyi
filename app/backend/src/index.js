import express from 'express';
import cors from 'cors';
import voteRoutes from './routes/votes.js';

const app = express();
const port = Number(process.env.PORT || 4000);
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:5173';

app.use(cors({ origin: corsOrigin }));
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/votes', voteRoutes);

app.listen(port, () => {
  console.log(`API en ecoute sur le port ${port}`);
});
