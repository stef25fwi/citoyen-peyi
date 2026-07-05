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

export const hasRole = (user, role) => user?.role === role || user?.[role] === true;

const hasAdminClaim = (user) => hasRole(user, 'admin');

const adminScopeFromUser = (user) => (
  typeof user?.adminScope === 'string' ? user.adminScope.trim().toLowerCase() : ''
);

export const isSuperAdmin = (user) => hasRole(user, 'super_admin');
export const isAdmin = (user) => isSuperAdmin(user) || (hasAdminClaim(user) && adminScopeFromUser(user) === 'global');
export const isCommuneAdmin = (user) => (
  isSuperAdmin(user)
  || hasRole(user, 'commune_admin')
  || (hasAdminClaim(user) && adminScopeFromUser(user) !== 'global')
);
export const isController = (user) => hasRole(user, 'controller') || user?.controller === true;

export const controllerIdFromUser = (user) => {
  if (typeof user?.controleurCodeId === 'string' && user.controleurCodeId.trim()) {
    return user.controleurCodeId.trim();
  }
  if (typeof user?.controllerId === 'string' && user.controllerId.trim()) {
    return user.controllerId.trim();
  }
  if (typeof user?.uid === 'string' && user.uid.startsWith('controller:')) {
    return user.uid.substring('controller:'.length);
  }
  return user?.uid || '';
};

export const communeScopeFromUser = (user) => {
  if (typeof user?.communeId === 'string' && user.communeId.trim()) return user.communeId.trim();
  if (typeof user?.communeCode === 'string' && user.communeCode.trim()) return user.communeCode.trim();
  return '';
};

export const requireRole = (predicate, message = 'Acces refuse.') => (req, res, next) => {
  if (predicate(req.user)) return next();
  return res.status(403).json({ message });
};

export const requireCommuneScope = (req, res, next) => {
  if (isSuperAdmin(req.user)) return next();
  const scope = communeScopeFromUser(req.user);
  if (!scope) {
    return res.status(403).json({ message: 'Aucune commune attachee au compte administrateur.' });
  }
  req.communeScope = scope;
  return next();
};

export const requireSuperAdmin = requireRole(isSuperAdmin, 'Reserve au super administrateur.');
export const requireCommuneAdmin = requireRole(isCommuneAdmin, 'Reserve aux administrateurs communaux.');
export const requireController = requireRole(isController, 'Reserve aux controleurs.');
