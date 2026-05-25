import { getFirebaseAdminAuth, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

export const requireFirebaseAuth = async (req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }

  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ message: 'Token Firebase requis.' });
  }

  try {
    req.user = await getFirebaseAdminAuth().verifyIdToken(match[1], true);
    return next();
  } catch (error) {
    req.log?.warn({ err: error }, 'invalid_firebase_token');
    return res.status(401).json({ message: 'Token Firebase invalide ou expire.' });
  }
};

const hasRole = (user, role) => user?.role === role || user?.[role] === true;

export const isSuperAdmin = (user) => hasRole(user, 'super_admin');
export const isCommuneAdmin = (user) => hasRole(user, 'admin') || hasRole(user, 'commune_admin') || isSuperAdmin(user);
export const isController = (user) => hasRole(user, 'controller') || user?.controller === true;

export const communeScopeFromUser = (user) => {
  if (typeof user?.communeId === 'string' && user.communeId.trim()) return user.communeId.trim();
  if (typeof user?.communeCode === 'string' && user.communeCode.trim()) return user.communeCode.trim();
  return '';
};

export const requireRole = (predicate, message = 'Acces refuse.') => (req, res, next) => {
  if (predicate(req.user)) return next();
  return res.status(403).json({ message });
};

export const requireSuperAdmin = requireRole(isSuperAdmin, 'Reserve au super administrateur.');
export const requireCommuneAdmin = requireRole(isCommuneAdmin, 'Reserve aux administrateurs communaux.');
export const requireController = requireRole(isController, 'Reserve aux controleurs.');
