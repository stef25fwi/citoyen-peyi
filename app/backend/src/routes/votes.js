import { Router } from 'express';
import { getResults, saveVote } from '../services/voteStore.js';

const router = Router();

router.post('/', (req, res) => {
  const { option } = req.body;

  if (!option || typeof option !== 'string') {
    return res.status(400).json({ error: 'Option invalide' });
  }

  saveVote(option);
  return res.status(201).json({ message: 'Vote enregistre' });
});

router.get('/results', (_req, res) => {
  res.json({ results: getResults() });
});

export default router;
