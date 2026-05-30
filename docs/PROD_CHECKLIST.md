# Production go-live checklist

## Secrets et configuration
- [ ] `SUPER_ADMIN_KEY` genere avec `openssl rand -base64 48`, stocke dans Secret Manager.
- [ ] `ADMIN_ACCESS_KEY` genere et utilise uniquement pour le bootstrap initial.
- [ ] `VOTE_ACCESS_TOKEN_SECRET` genere avec `openssl rand -base64 64`.
- [ ] Service account Firebase Admin avec scope minimal (Firestore User).
- [ ] `CORS_ORIGIN` configure avec uniquement le domaine prod du frontend (HTTPS).
- [ ] Variables GitHub Actions definies: `GCP_PROJECT_ID`, `GCP_REGION`, `API_BASE_URL`, `CORS_ORIGIN`, `FIREBASE_PROJECT_ID`.
- [ ] Secrets GitHub Actions definis: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT`, `GCP_RUNTIME_SERVICE_ACCOUNT`, `FIREBASE_*` (x6).

## Code et tests
- [ ] CI vert sur la branche cible (backend tests, Flutter analyze + test, Firestore rules emulator).
- [ ] `npm audit --omit=dev` revu, vulnerabilites tracables a `firebase-admin` documentees.
- [ ] Aucun grep ne retourne `ADMIN2026`, `change-me`, `fallback` actif dans `flutter_app/lib`.

## Infrastructure
- [ ] Cloud Run service `citoyen-peyi-api` cree en `eu-west1` (ou region la plus proche).
- [ ] Artifact Registry repo `citoyen-peyi/backend` cree.
- [ ] Domain mapping `api.citoyen-peyi.<tld>` -> Cloud Run.
- [ ] GitHub Pages domain mapping (optionnel) `app.citoyen-peyi.<tld>`.
- [ ] Backup Firestore quotidien programme.
- [ ] Alertes Cloud Monitoring: p95 > 1s, error rate > 1%, instance count saturee.

## Donnees
- [ ] Toutes les collections de demonstration supprimees (`polls/poll-1`, controleurs `ADMIN2026`).
- [ ] `registrationCodes` migrees vers `citizen_access_codes` via `npm run migrate:registration-codes`.
- [ ] Premiers profils `communeAdmins` et `controleurCodes` crees via les nouveaux endpoints backend.

## QA fonctionnelle (depuis `docs/CITOYEN_PEYI_FLOW_QA.md`)
- [ ] Flow super-admin OK
- [ ] Flow admin communal OK
- [ ] Flow controleur OK
- [ ] Flow citoyen + tentative de double vote bloque cote backend
- [ ] Health endpoints (`/api/health/live`, `/api/health/ready`) verifies depuis l'exterieur

## Securite
- [ ] Headers helmet verifies (`curl -I https://$API/api/health/live`).
- [ ] Rate-limit observe (10 reqs/min sur `/api/auth/*` provoquent un 429).
- [ ] Logs ne contiennent jamais `accessKey`, `Authorization`, `x-super-admin-key` (redacted par pino).
- [ ] Scan ZAP baseline lance contre l'API et le frontend.
- [ ] App Check active sur Firebase: cle reCAPTCHA v3 enregistree avec
      `stef25fwi.github.io`, `localhost`, `127.0.0.1` et le domaine prod custom.
- [ ] App Check enforcement = `Enforced` pour Firestore et Authentication
      apres validation prod (sinon laisser `Unenforced`).

## Anonymat production 10/10

Etat repo: les briques code, tests et documentation existent. Cocher cette
section uniquement pendant la validation de l'environnement production reel.

Critere d'acceptation:

> Pour une consultation donnee, la base de donnees permet de savoir qu'un droit
> de vote a ete consomme et combien de voix chaque option a recues, mais elle ne
> contient aucun document durable permettant de relier un code citoyen, une
> empreinte citoyenne, un controleur ou un accessCodeId a l'option choisie.

- [ ] 1. Relire le modele de menace: `docs/ANONYMITY_THREAT_MODEL.md` documente
      les actifs, adversaires, garanties, limites et verifications production.
- [ ] 2. Configurer `PARTICIPATION_PEPPER`: secret HMAC dedie, requis en
      production et distinct des autres peppers.
- [ ] 3. Verifier que les identifiants sensibles sont absents du token de vote:
      le jeton court transporte uniquement `pollId`, `communeId`,
      `participationHash` et `exp`.
- [ ] 4. Verifier `poll_participations`: collection de consommation du droit de vote,
      sans `optionId` ni donnees citoyennes.
- [ ] 5. Verifier `poll_ballots`: collection de bulletins anonymes avec seulement
      `pollId`, `optionId`, `communeId` et `castAt`.
- [ ] 6. Verifier la transaction de vote: une seule transaction cree la
      participation, cree le bulletin anonyme et incremente l'agregat public.
- [ ] 7. Deployer et tester les regles Firestore: `poll_votes`, `poll_participations`
      et `poll_ballots` sont fermes aux clients; les resultats publics restent
      lisibles via `polls`.
- [ ] 8. Lancer les tests d'anonymat: vote unique, double vote, concurrence,
      absence de lien durable et acces public aux resultats agreges.
- [ ] 9. Executer la strategie legacy `poll_votes`: sauvegarde controlee,
      archive agregee uniquement, puis suppression sans migration document par document.
- [ ] 10. Auditer logs et donnees existantes: redaction des champs sensibles,
      absence de `optionId` dans les logs correles, et controle des exports avant prod.

Niveau cryptographique superieur: pour pouvoir affirmer que meme le serveur ne
peut pas relier l'autorisation initiale au bulletin final, planifier une phase
dediee de jeton aveugle ou signature aveugle avec design crypto, revue externe
et tests de non-correlation.
