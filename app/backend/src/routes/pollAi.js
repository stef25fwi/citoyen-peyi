import express from 'express';
import {
  requireCommuneAdmin,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';
import { env } from '../config/env.js';
import { logger } from '../services/logger.js';

const router = express.Router();

const sanitizeString = (value, max = 1000) => (
  typeof value === 'string' ? value.trim().substring(0, max) : ''
);

const sanitizeOptions = (value) => {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => sanitizeString(item?.label ?? item, 200))
    .filter(Boolean)
    .slice(0, 12);
};

const safeJsonParse = (value) => {
  const raw = sanitizeString(value, 12000);
  if (!raw) return null;

  const cleaned = raw
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/```$/i, '')
    .trim();

  try {
    return JSON.parse(cleaned);
  } catch (_) {
    const first = cleaned.indexOf('{');
    const last = cleaned.lastIndexOf('}');
    if (first >= 0 && last > first) {
      try {
        return JSON.parse(cleaned.substring(first, last + 1));
      } catch (_) {}
    }
  }

  return null;
};

const buildPrompt = ({ projectTitle, description, question, targetPopulation, options }) => `
Tu es assistant de redaction pour une consultation citoyenne communale.

Objectif:
- Reformuler les champs pour les rendre clairs, neutres, professionnels et comprehensibles par les citoyens.
- Garder le sens initial de l'administrateur communal.
- Ne pas inventer de nouvelle decision, de budget, de promesse ou d'information absente.
- Conserver le meme nombre d'options de vote.
- Utiliser un francais simple, institutionnel et accessible.
- Eviter tout ton partisan ou orientant le vote.

Retourne uniquement un JSON valide au format exact:
{
  "projectTitle": "...",
  "description": "...",
  "question": "...",
  "targetPopulation": "...",
  "options": ["...", "..."]
}

Texte original:
Titre: ${projectTitle}
Description: ${description}
Question: ${question}
Population cible: ${targetPopulation}
Options: ${JSON.stringify(options)}
`;

router.use(requireFirebaseAuth, requireCommuneAdmin);

router.post('/rewrite', async (req, res, next) => {
  try {
    const apiKey = env.geminiApiKey;
    if (!apiKey) {
      return res.status(503).json({
        message: 'Assistant IA indisponible: GEMINI_API_KEY non configuree cote backend.',
      });
    }

    const input = {
      projectTitle: sanitizeString(req.body?.projectTitle, 200),
      description: sanitizeString(req.body?.description, 2000),
      question: sanitizeString(req.body?.question, 300),
      targetPopulation: sanitizeString(req.body?.targetPopulation, 300),
      options: sanitizeOptions(req.body?.options),
    };

    if (!input.projectTitle || !input.question || input.options.length < 2) {
      return res.status(400).json({
        message: 'Renseignez au minimum le titre, la question et deux options avant de lancer l assistant IA.',
      });
    }

    const model = sanitizeString(env.geminiModel || 'gemini-3.5-flash', 80)
      .replace(/^models\//, '');

    const url = new URL(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    );
    url.searchParams.set('key', apiKey);

    const aiResponse = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [{ text: buildPrompt(input) }],
          },
        ],
        generationConfig: {
          temperature: 0.35,
          maxOutputTokens: 1200,
          responseMimeType: 'application/json',
        },
      }),
    });

    const responseText = await aiResponse.text();

    if (!aiResponse.ok) {
      logger.warn(
        { status: aiResponse.status, body: responseText.substring(0, 500) },
        'poll_ai_rewrite_failed',
      );
      return res.status(502).json({
        message: 'L assistant IA Google n a pas pu reformuler la consultation.',
      });
    }

    let payload = {};
    try {
      payload = JSON.parse(responseText);
    } catch (_) {
      payload = {};
    }

    const text = payload?.candidates?.[0]?.content?.parts
      ?.map((part) => part?.text || '')
      ?.join('\n') || '';

    const parsed = safeJsonParse(text);
    if (!parsed || typeof parsed !== 'object') {
      return res.status(502).json({
        message: 'La proposition IA est illisible. Reessayez.',
      });
    }

    const proposal = {
      projectTitle: sanitizeString(parsed.projectTitle, 200) || input.projectTitle,
      description: sanitizeString(parsed.description, 2000) || input.description,
      question: sanitizeString(parsed.question, 300) || input.question,
      targetPopulation: sanitizeString(parsed.targetPopulation, 300) || input.targetPopulation,
      options: sanitizeOptions(parsed.options),
    };

    if (proposal.options.length !== input.options.length) {
      proposal.options = input.options;
    }

    if (proposal.options.length < 2) {
      proposal.options = input.options;
    }

    return res.json({ proposal });
  } catch (error) {
    return next(error);
  }
});

export default router;
