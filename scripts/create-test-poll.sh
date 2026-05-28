#!/usr/bin/env bash
# Cree une consultation de test via l'API backend.
#
# Variables requises :
#   ADMIN_ACCESS_KEY  Cle administrateur communal (ou bootstrap).
#   FIREBASE_API_KEY  Cle web Firebase (echange customToken -> idToken).
#
# Variables optionnelles :
#   API_BASE_URL      Defaut: https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app
#   COMMUNE_ID        Defaut: lu depuis la reponse admin/exchange.
#   COMMUNE_NAME      Defaut: lu depuis la reponse admin/exchange.
#   PROJECT_TITLE     Defaut: "Test pipeline <date>"
#   QUESTION          Defaut: "Approuvez-vous le deploiement test ?"
#   OPEN_DATE         Defaut: aujourd'hui (YYYY-MM-DD)
#   CLOSE_DATE        Defaut: aujourd'hui + 7 jours
#   PUBLISH           Si "1", publie la consultation apres creation.

set -euo pipefail

: "${ADMIN_ACCESS_KEY:?ADMIN_ACCESS_KEY requis}"
: "${FIREBASE_API_KEY:?FIREBASE_API_KEY requis}"
API_BASE_URL="${API_BASE_URL:-https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app}"

command -v jq >/dev/null || { echo "jq requis (sudo apt-get install -y jq)" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl requis" >&2; exit 1; }

today="$(date -u +%Y-%m-%d)"
plus7="$(date -u -d '+7 days' +%Y-%m-%d)"

PROJECT_TITLE="${PROJECT_TITLE:-Test pipeline ${today}}"
QUESTION="${QUESTION:-Approuvez-vous le deploiement test ?}"
OPEN_DATE="${OPEN_DATE:-$today}"
CLOSE_DATE="${CLOSE_DATE:-$plus7}"

echo "==> 1/4 Echange cle admin -> customToken"
exchange_payload="$(jq -nc --arg k "$ADMIN_ACCESS_KEY" '{accessKey:$k}')"
exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/admin/exchange" \
  -H 'Content-Type: application/json' \
  -d "$exchange_payload")"

custom_token="$(jq -er '.customToken' <<<"$exchange_resp")"
COMMUNE_ID="${COMMUNE_ID:-$(jq -r '.profile.communeId // ""' <<<"$exchange_resp")}"
COMMUNE_NAME="${COMMUNE_NAME:-$(jq -r '.profile.communeName // ""' <<<"$exchange_resp")}"

if [[ -z "$COMMUNE_ID" ]]; then
  echo "COMMUNE_ID introuvable (profil bootstrap ?). Renseignez COMMUNE_ID=... avant de relancer." >&2
  exit 2
fi

echo "    commune: ${COMMUNE_NAME:-?} (${COMMUNE_ID})"

echo "==> 2/4 Echange customToken -> idToken (Firebase Auth REST)"
id_token_resp="$(curl -sS -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg t "$custom_token" '{token:$t,returnSecureToken:true}')")"

id_token="$(jq -er '.idToken' <<<"$id_token_resp")"

echo "==> 3/4 Creation consultation"
poll_payload="$(jq -nc \
  --arg pt "$PROJECT_TITLE" \
  --arg q "$QUESTION" \
  --arg od "$OPEN_DATE" \
  --arg cd "$CLOSE_DATE" \
  --arg ci "$COMMUNE_ID" \
  --arg cn "$COMMUNE_NAME" \
  '{
     projectTitle:$pt,
     description:"Consultation de validation pipeline (creation auto).",
     question:$q,
     options:[{label:"Oui"},{label:"Non"}],
     targetPopulation:"Habitants test",
     openDate:$od,
     closeDate:$cd,
     communeId:$ci,
     communeName:$cn,
     totalVoters:1000
   }')"

create_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls" \
  -H "Authorization: Bearer $id_token" \
  -H 'Content-Type: application/json' \
  -d "$poll_payload")"

poll_id="$(jq -er '.poll.id' <<<"$create_resp")"
echo "    consultation creee: $poll_id"

if [[ "${PUBLISH:-0}" == "1" ]]; then
  echo "==> 4/4 Publication"
  publish_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls/$poll_id/publish" \
    -H "Authorization: Bearer $id_token")"
  echo "    statut: $(jq -r '.poll.status // .message // "?"' <<<"$publish_resp")"
else
  echo "==> 4/4 Publication ignoree (PUBLISH=1 pour activer)"
fi

echo
echo "OK. Consultation:"
jq '{id:.poll.id,projectTitle:.poll.projectTitle,status:.poll.status,openDate:.poll.openDate,closeDate:.poll.closeDate,options:.poll.options}' <<<"$create_resp"
