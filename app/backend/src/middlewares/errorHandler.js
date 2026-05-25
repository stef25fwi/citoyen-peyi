import { logger } from '../services/logger.js';

export const notFoundHandler = (_req, res) => {
  res.status(404).json({ message: 'Route inconnue.' });
};

// eslint-disable-next-line no-unused-vars
export const errorHandler = (err, req, res, _next) => {
  const status = Number(err?.status) >= 400 && Number(err?.status) < 600 ? Number(err.status) : 500;
  const log = req.log ?? logger;
  log.error({ err, status, url: req.url, method: req.method }, 'unhandled_route_error');
  if (res.headersSent) return;
  res.status(status).json({
    message: status >= 500 ? 'Erreur interne du serveur.' : (err?.message || 'Requete invalide.'),
  });
};

export const registerProcessHandlers = () => {
  process.on('unhandledRejection', (reason) => {
    logger.error({ reason }, 'unhandled_rejection');
  });
  process.on('uncaughtException', (err) => {
    logger.fatal({ err }, 'uncaught_exception');
    setTimeout(() => process.exit(1), 100).unref();
  });
};
