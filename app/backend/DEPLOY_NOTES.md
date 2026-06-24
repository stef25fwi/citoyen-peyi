# Notes de déploiement backend

## Rotation des secrets (SUPER_ADMIN_KEY, peppers, etc.)

Les secrets sont montés en `:latest` par le workflow `deploy-backend.yml`
(`--set-secrets=SUPER_ADMIN_KEY=SUPER_ADMIN_KEY:latest, ...`).

Conséquence : **ajouter une nouvelle version d'un secret ne suffit pas** — elle
n'est prise en compte qu'au **prochain déploiement** d'une nouvelle révision
Cloud Run. Après une rotation (`gcloud secrets versions add ...`), il faut donc
**redéployer** le backend :

- Bouton GitHub : Actions → « Deploy backend (Cloud Run) » → Run workflow → `main`.
- Ou tout push touchant `app/backend/**` sur `main`.

La valeur active est celle de la version `:latest` **au moment du déploiement**.
Pensez à noter la nouvelle clé hors du dépôt et à ne jamais la committer.

<!-- redeploy trigger: rotation SUPER_ADMIN_KEY (v8) -->
