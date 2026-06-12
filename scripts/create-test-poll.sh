#!/usr/bin/env bash
# Cree une consultation de test via l'API backend.
#
# Auth (au choix) :
#   ADMIN_ACCESS_KEY  Cle administrateur communal -> consultation dans SA commune.
#   SUPER_ADMIN_KEY   Cle super admin -> consultation pour COMMUNE_ID (obligatoire).
#   FIREBASE_API_KEY  Cle web Firebase (echange customToken -> idToken). Requise.
#
# Variables optionnelles :
#   API_BASE_URL      Defaut: https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app
#   COMMUNE_ID        Mode admin: lu depuis admin/exchange. Mode super admin: REQUIS (ex 97109).
#   COMMUNE_NAME      Defaut: lu depuis admin/exchange, sinon COMMUNE_ID.
#   PROJECT_TITLE     Defaut: "Test pipeline <date>"
#   QUESTION          Defaut: "Approuvez-vous le deploiement test ?"
#   OPEN_DATE         Defaut: aujourd'hui (YYYY-MM-DD)
#   CLOSE_DATE        Defaut: aujourd'hui + 7 jours
#   PUBLISH           Si "1", publie la consultation apres creation.

set -euo pipefail

: "${FIREBASE_API_KEY:?FIREBASE_API_KEY requis}"
if [[ -z "${ADMIN_ACCESS_KEY:-}" && -z "${SUPER_ADMIN_KEY:-}" ]]; then
  echo "ADMIN_ACCESS_KEY ou SUPER_ADMIN_KEY requis (mode super admin: definir aussi COMMUNE_ID)." >&2
  exit 1
fi
API_BASE_URL="${API_BASE_URL:-https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app}"

command -v jq >/dev/null || { echo "jq requis (sudo apt-get install -y jq)" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl requis" >&2; exit 1; }

fail_with_payload() {
  local step="$1"
  local payload="$2"
  echo "ECHEC_${step}" >&2
  if jq -e . >/dev/null 2>&1 <<<"$payload"; then
    jq . <<<"$payload" >&2
  else
    printf '%s\n' "$payload" >&2
  fi
  exit 1
}

today="$(date -u +%Y-%m-%d)"
plus7="$(date -u -d '+7 days' +%Y-%m-%d)"

PROJECT_TITLE="${PROJECT_TITLE:-Test pipeline ${today}}"
QUESTION="${QUESTION:-Approuvez-vous le deploiement test ?}"
OPEN_DATE="${OPEN_DATE:-$today}"
CLOSE_DATE="${CLOSE_DATE:-$plus7}"

if [[ -n "${SUPER_ADMIN_KEY:-}" ]]; then
  echo "==> 1/4 Echange cle super admin -> customToken"
  : "${COMMUNE_ID:?COMMUNE_ID requis en mode super admin (ex: 97109)}"
  exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/super/exchange" \
    -H 'Content-Type: application/json' \
    -H "x-super-admin-key: $SUPER_ADMIN_KEY" \
    -d '{}')"
  custom_token="$(jq -r '.customToken // empty' <<<"$exchange_resp")"
  if [[ -z "$custom_token" ]]; then
    fail_with_payload "SUPER_EXCHANGE" "$exchange_resp"
  fi
  COMMUNE_NAME="${COMMUNE_NAME:-$COMMUNE_ID}"
else
  echo "==> 1/4 Echange cle admin -> customToken"
  exchange_payload="$(jq -nc --arg k "$ADMIN_ACCESS_KEY" '{accessKey:$k}')"
  exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/admin/exchange" \
    -H 'Content-Type: application/json' \
    -d "$exchange_payload")"
  custom_token="$(jq -r '.customToken // empty' <<<"$exchange_resp")"
  if [[ -z "$custom_token" ]]; then
    fail_with_payload "ADMIN_EXCHANGE" "$exchange_resp"
  fi
  COMMUNE_ID="${COMMUNE_ID:-$(jq -r '.profile.communeId // ""' <<<"$exchange_resp")}"
  COMMUNE_NAME="${COMMUNE_NAME:-$(jq -r '.profile.communeName // ""' <<<"$exchange_resp")}"
fi

if [[ -z "$COMMUNE_ID" ]]; then
  echo "COMMUNE_ID introuvable. Renseignez COMMUNE_ID=... avant de relancer." >&2
  exit 2
fi

echo "    commune: ${COMMUNE_NAME:-?} (${COMMUNE_ID})"

echo "==> 2/4 Echange customToken -> idToken (Firebase Auth REST)"
id_token_resp="$(curl -sS -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg t "$custom_token" '{token:$t,returnSecureToken:true}')")"

id_token="$(jq -r '.idToken // empty' <<<"$id_token_resp")"
if [[ -z "$id_token" ]]; then
  fail_with_payload "FIREBASE_CUSTOM_TOKEN" "$id_token_resp"
fi

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

poll_id="$(jq -r '.poll.id // empty' <<<"$create_resp")"
if [[ -z "$poll_id" ]]; then
  fail_with_payload "CREATE_POLL" "$create_resp"
fi
echo "    consultation creee: $poll_id"

if [[ "${PUBLISH:-0}" == "1" ]]; then
  echo "==> 4/4 Publication"
  publish_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls/$poll_id/publish" \
    -H "Authorization: Bearer $id_token")"
  # L'endpoint /publish renvoie {ok,status} a plat (pas .poll.status). On accepte
  # les deux formes pour eviter un faux ECHEC quand la publication a reussi.
  publish_status="$(jq -r '.poll.status // .status // empty' <<<"$publish_resp")"
  publish_ok="$(jq -r '.ok // false' <<<"$publish_resp")"
  if [[ -z "$publish_status" && "$publish_ok" != "true" ]]; then
    fail_with_payload "PUBLISH_POLL" "$publish_resp"
  fi
  publish_status="${publish_status:-active}"
  echo "    statut: $publish_status"
else
  echo "==> 4/4 Publication ignoree (PUBLISH=1 pour activer)"
fi

echo
echo "OK. Consultation:"
jq '{id:.poll.id,projectTitle:.poll.projectTitle,status:.poll.status,openDate:.poll.openDate,closeDate:.poll.closeDate,options:.poll.options}' <<<"$create_resp"
