#!/usr/bin/env bash
# Niveau 1 — Sauvegarde managee GCP (filet de securite catastrophe).
#
# Met en place :
#   1) un bucket GCS prive dedie aux snapshots (Niveau 2 applicatif + exports),
#   2) une planification de sauvegardes Firestore natives (point-in-time),
#   3) (commande) un export Firestore a la demande vers GCS.
#
# Idempotent autant que possible (les "create" deja existants sont ignores avec
# un message). A executer avec un compte ayant les droits Owner/Editor projet.
set -euo pipefail

PROJECT="${GCP_PROJECT_ID:-citoyen-peyi}"
REGION="${GCP_REGION:-europe-west1}"
DATABASE="${FIRESTORE_DATABASE:-(default)}"
BUCKET="${BACKUP_BUCKET:-${PROJECT}-backups}"
RUNTIME_SA="${GCP_RUNTIME_SERVICE_ACCOUNT:-1087566305566-compute@developer.gserviceaccount.com}"
RETENTION="${BACKUP_RETENTION:-14d}"
RECURRENCE="${BACKUP_RECURRENCE:-daily}" # daily | weekly

echo "Projet=${PROJECT} Region=${REGION} Bucket=gs://${BUCKET} DB=${DATABASE}"

# 1) Bucket prive dedie -------------------------------------------------------
if gcloud storage buckets describe "gs://${BUCKET}" --project="${PROJECT}" >/dev/null 2>&1; then
  echo "Bucket gs://${BUCKET} existant — OK."
else
  gcloud storage buckets create "gs://${BUCKET}" \
    --project="${PROJECT}" --location="${REGION}" \
    --uniform-bucket-level-access --public-access-prevention
  echo "Bucket gs://${BUCKET} cree (acces uniforme + public access prevention)."
fi

# Cycle de vie : purge des objets > 90 jours (ajuster au besoin).
cat >/tmp/citoyen-peyi-backup-lifecycle.json <<'JSON'
{ "rule": [ { "action": {"type": "Delete"}, "condition": {"age": 90} } ] }
JSON
gcloud storage buckets update "gs://${BUCKET}" \
  --lifecycle-file=/tmp/citoyen-peyi-backup-lifecycle.json --project="${PROJECT}"

# Le SA runtime (backend Cloud Run) lit/ecrit les snapshots applicatifs.
gcloud storage buckets add-iam-policy-binding "gs://${BUCKET}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/storage.objectAdmin" --project="${PROJECT}"

# Les URL signees v4 exigent que le SA runtime puisse signer (tokenCreator sur
# lui-meme) — deja requis pour createCustomToken (voir OPERATIONS §1c).
gcloud iam service-accounts add-iam-policy-binding "${RUNTIME_SA}" \
  --member="serviceAccount:${RUNTIME_SA}" \
  --role="roles/iam.serviceAccountTokenCreator" --project="${PROJECT}" || true

# 2) Sauvegardes Firestore natives planifiees (point-in-time) -----------------
# Necessite l'API Firestore et un plan compatible. Ignore si deja presente.
if gcloud firestore backups schedules list --database="${DATABASE}" --project="${PROJECT}" 2>/dev/null | grep -q "${RECURRENCE}"; then
  echo "Planification de sauvegarde Firestore (${RECURRENCE}) deja presente — OK."
else
  if [ "${RECURRENCE}" = "weekly" ]; then
    gcloud firestore backups schedules create \
      --database="${DATABASE}" --project="${PROJECT}" \
      --retention="${RETENTION}" --recurrence=weekly --day-of-week=SUNDAY
  else
    gcloud firestore backups schedules create \
      --database="${DATABASE}" --project="${PROJECT}" \
      --retention="${RETENTION}" --recurrence=daily
  fi
  echo "Planification de sauvegarde Firestore creee (${RECURRENCE}, retention ${RETENTION})."
fi

echo
echo "Termine."
echo "Export Firestore a la demande vers GCS :"
echo "  gcloud firestore export gs://${BUCKET}/exports/\$(date +%Y%m%d-%H%M%S) \\"
echo "    --database='${DATABASE}' --project='${PROJECT}'"
echo
echo "Import d'un export (restauration tout-ou-rien) :"
echo "  gcloud firestore import gs://${BUCKET}/exports/<DOSSIER> \\"
echo "    --database='${DATABASE}' --project='${PROJECT}'"
