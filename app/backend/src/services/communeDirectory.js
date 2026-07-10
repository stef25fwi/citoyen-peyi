// Consolidation des communes : evite que des comptes (admins communaux, agents
// de mobilisation citoyenne) soient "eparpilles" sur des variantes du meme lieu
// (meme code INSEE ecrit avec des noms/codes postaux differents).
//
// La cle canonique d'une commune est son code INSEE (`communeCode`). Des qu'un
// admin communal existe pour ce code, son identite (nom + code postal) fait
// foi : tout nouveau compte cree pour ce code s'y rattache automatiquement au
// lieu d'introduire une variante.

const ADMIN_COLLECTION = 'communeAdmins';

const clean = (value) => (typeof value === 'string' ? value.trim() : '');

/**
 * Retourne l'identite canonique de la commune pour les valeurs fournies.
 * Si un admin communal existe deja pour ce code INSEE, on adopte son nom et son
 * code postal ; sinon on renvoie les valeurs saisies telles quelles.
 *
 * @returns {Promise<{communeCode: string, communeName: string, codePostal: string, matched: boolean, matchedAdminId: string|null}>}
 */
export const resolveCanonicalCommune = async (db, {
  communeCode,
  communeName,
  codePostal,
} = {}) => {
  const code = clean(communeCode);
  const name = clean(communeName);
  const postal = clean(codePostal);

  if (!code) {
    return {
      communeCode: code,
      communeName: name,
      codePostal: postal,
      matched: false,
      matchedAdminId: null,
    };
  }

  const snapshot = await db
    .collection(ADMIN_COLLECTION)
    .where('communeCode', '==', code)
    .limit(1)
    .get();

  if (snapshot.empty) {
    return {
      communeCode: code,
      communeName: name,
      codePostal: postal,
      matched: false,
      matchedAdminId: null,
    };
  }

  const doc = snapshot.docs[0];
  const data = doc.data() || {};
  return {
    communeCode: code,
    // On privilegie l'identite existante ; on retombe sur la saisie si un champ
    // manque cote base.
    communeName: clean(data.communeName) || name,
    codePostal: clean(data.codePostal) || postal,
    matched: true,
    matchedAdminId: doc.id,
  };
};
