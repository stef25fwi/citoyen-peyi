# Citoyen Peyi - Checklist QA du flow utilisateur

Cette checklist couvre les criteres d'acceptation du flow citoyen / controleur /
administrateur communal / super administrateur. Tous les tests sont a executer
avant un deploiement de production.

## Pre-requis backend

- Variables d'environnement renseignees:
  - `FIREBASE_*` (Admin SDK service account)
  - `ADMIN_ACCESS_KEY` (cle admin globale, utilisee uniquement pour bootstrap)
  - `SUPER_ADMIN_KEY` (acces aux endpoints super admin)
  - `VOTE_ACCESS_TOKEN_SECRET` (signature des accessToken citoyens, TTL 30 min)
- Firestore configure avec les collections:
  - `polls` (consultations communales)
  - `citizen_access_codes` (codes citoyens, source officielle)
  - `citizen_fingerprints` (detection doublon)
  - `duplicate_code_requests` (workflow super admin)
  - `controller_activity_logs` (audit controleurs)
  - `controleurCodes` (codes controleurs)
  - `poll_votes` (vote unique par {pollId}_{accessCodeId}, ecriture backend uniquement)
  - `public_news` (actualites communales)
- Regles Firestore deployees depuis `vote-libre-main/firestore.rules`.

## Flow super administrateur

- [ ] Connexion super admin avec la cle `SUPER_ADMIN_KEY`.
- [ ] Le tableau de bord liste les communes / controleurs / activites.
- [ ] Creer un profil administrateur communal (commune + nom + code) :
      le code admin retourne doit fonctionner sur l'ecran admin/login.
- [ ] Voir l'activite globale puis filtrer sur une commune ou un controleur.
- [ ] Cliquer "Voir activite" depuis la fiche d'un controleur :
      le filtre `controllerId` doit etre pre-rempli automatiquement.
- [ ] Approuver / refuser une demande de regeneration de code :
      le statut `duplicate_code_requests` est mis a jour, un nouveau code
      `citizen_access_codes` est cree, l'ancien passe en `replaced`.

## Flow administrateur communal

- [ ] Connexion via le code admin emis par le super administrateur.
- [ ] La cle globale `ADMIN_ACCESS_KEY` n'est utilisable que pour le bootstrap
      initial: aucune session admin ne doit s'ouvrir avec une cle invalide.
- [ ] Creer une consultation: le champ "Objectif de participation" est
      explicitement decrit comme une estimation. Aucun stock de QR n'est genere
      a cette etape.
- [ ] Publier la consultation, suivre la participation, voir les controleurs.
- [ ] Cloturer la consultation: l'etat passe a `closed`, plus de votes possibles.
- [ ] Consulter les resultats anonymises (aucune donnee personnelle).

## Flow controleur

- [ ] Connexion via le code controleur cree par l'administrateur communal.
- [ ] Saisir les elements de verification (initiales + annee + 2 derniers
      chiffres du telephone) et cocher les pieces presentees.
- [ ] Generer un code citoyen :
  - Pas de doublon -> code + QR retournes par le backend.
  - Doublon detecte -> demande automatique transmise au super admin.
- [ ] Verifier l'historique du controleur (derniers codes generes).

## Flow citoyen

- [ ] Saisir un code citoyen invalide -> message d'erreur clair (`INVALID_CODE`).
- [ ] Saisir un code citoyen valide, une seule consultation ouverte ->
      navigation directe vers `/vote/:code?poll=...`.
- [ ] Saisir un code citoyen valide, plusieurs consultations ouvertes ->
      ecran "Choisissez la consultation".
- [ ] Voter une fois -> le backend cree `poll_votes/{pollId}_{accessCodeId}`,
      incremente l'option et marque le code (`lastUsedAt`).
- [ ] Tenter de voter une seconde fois pour le meme sondage -> message
      `ALREADY_VOTED` ; aucun double vote n'est possible.
- [ ] Ouvrir deux onglets et tenter un double vote concurrent -> un seul vote
      enregistre cote serveur (transaction Firestore).
- [ ] Consulter `/results` : les totaux par option et par commune sont visibles,
      aucune donnee personnelle n'est exposee.
- [ ] Consulter `/news` : empty state propre si aucune actualite.

## Securite & integrite

- [ ] Les regles Firestore bloquent toute lecture publique de
      `citizen_access_codes`, `citizen_fingerprints`, `poll_votes`,
      `duplicate_code_requests`, `controller_activity_logs`.
- [ ] L'API `/api/vote-access/validate` rejette les codes inconnus, expires,
      revoques et retourne `accessToken` HMAC-signe (TTL 30 min).
- [ ] L'API `/api/vote-access/submit` est strictement transactionnelle :
      verification token + commune + sondage ouvert + option valide + non
      duplique avant ecriture.
- [ ] Aucune cle ou secret n'est embarque dans les bundles client.
- [ ] Les noms / prenoms complets ne sont jamais persistes (initiales + hash).

## Commandes de validation

```bash
# Flutter web
cd flutter_app
flutter pub get
flutter analyze
flutter test

# Backend
cd app/backend
npm install
npm test || true

# Build production GitHub Pages
cd ../../flutter_app
flutter build web --release --base-href /citoyen-peyi/
```
