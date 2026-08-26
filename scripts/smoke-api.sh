#!/usr/bin/env bash
# API smoke test "real conditions" — launch sprint, Phase 0.
#
# Creates a real Supabase user, exercises the backend (register → profile →
# calculation → documents), then deletes the account (DELETE /users/me). Along the
# way, validates SUPABASE_SERVICE_ROLE_KEY (Storage upload + auth deletion).
#
# Usage: scripts/smoke-api.sh [API_BASE_URL]   (default http://localhost:7777)
# Prerequisites: backend listening + mobile/.env filled in (SUPABASE_URL + anon key).
set -euo pipefail

API="${1:-http://localhost:7777}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPABASE_URL=$(sed -n 's/^SUPABASE_URL=//p' "$ROOT/mobile/.env" | tr -d ' \r"')
ANON=$(sed -n 's/^SUPABASE_ANON_KEY=//p' "$ROOT/mobile/.env" | tr -d ' \r"')
[ -n "$SUPABASE_URL" ] && [ -n "$ANON" ] || { echo "❌ mobile/.env incomplet"; exit 1; }

EMAIL="pocketpillar.smoke+$(date +%s)@gmail.com"
PASSWORD="Smoke-$(openssl rand -hex 12)-!"
SERVICE=$(sed -n 's/^SUPABASE_SERVICE_ROLE_KEY=//p' "$ROOT/.env" | tr -d ' \r"')
[ -n "$SERVICE" ] || { echo "❌ SUPABASE_SERVICE_ROLE_KEY absente du .env racine"; exit 1; }

jqget() { python3 -c "import json,sys
d=json.load(sys.stdin)
print($1)"; }

step=0
say() { step=$((step + 1)); echo "→ $step/7 $1"; }

# Cleanup even on an intermediate failure: no orphans left in Supabase.
TOKEN=""
cleanup() {
  if [ -n "$TOKEN" ]; then
    echo "   🧹 nettoyage après interruption…"
    curl -sS -X DELETE -H "Authorization: Bearer $TOKEN" -o /dev/null "$API/users/me" || true
  fi
}
trap cleanup EXIT

# 1 — Create admin (pre-confirmed email, no email sent — avoids the project's
# "Confirm email" rate limit) + login. Validates the service role key.
say "Création admin Supabase + login ($EMAIL)"
CREATE=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE" -H "Authorization: Bearer $SERVICE" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"email_confirm\":true}")
SUID=$(echo "$CREATE" | jqget "d.get('id') or ''")
[ -n "$SUID" ] || { echo "❌ création admin : $CREATE" | head -c 300; echo; exit 1; }
LOGIN=$(curl -sS -X POST "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$LOGIN" | jqget "d.get('access_token') or ''")
[ -n "$TOKEN" ] || { echo "❌ login : $LOGIN" | head -c 300; echo; exit 1; }
echo "   ✅ session obtenue (service role key valide)"
AUTH="Authorization: Bearer $TOKEN"

req() { # req METHOD PATH [JSON] → "body\nCODE_HTTP" on stdout
  local method="$1" path="$2" body="${3:-}"
  local args=(-sS -X "$method" -H "$AUTH")
  # Content-Type JSON only if there's a body (Fastify rejects an empty body declared as JSON).
  [ -n "$body" ] && args+=(-H "Content-Type: application/json" -d "$body")
  curl "${args[@]}" -w $'\n%{http_code}' "$API$path"
}

# 2 — Register backend (creates the users row)
say "POST /auth/register"
OUT=$(req POST /auth/register "{\"supabaseId\":\"$SUID\",\"email\":\"$EMAIL\"}")
CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] || { echo "❌ $CODE $OUT"; exit 1; }
echo "   ✅ user backend $(echo "$OUT" | jqget "d['id']")"

# 3 — User profile (canton, birth year) + re-read
say "PATCH puis GET /users/me"
OUT=$(req PATCH /users/me '{"canton":"VD","birthYear":1991,"replacementRateGoal":70}')
CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] || { echo "❌ $CODE $OUT"; exit 1; }
OUT=$(req GET /users/me); CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] && echo "$OUT" | grep -q '"canton":"VD"' || { echo "❌ $CODE $OUT"; exit 1; }
echo "$OUT" | grep -q '"premium"' && echo "   ✅ profil lu, bloc premium présent"

# 4 — Financial profile
say "PUT /financial-profile"
OUT=$(req PUT /financial-profile '{"employmentStatus":"EMPLOYED","maritalStatus":"SINGLE","numberOfChildren":0,"grossAnnualIncome":9500000}')
CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] || [ "$CODE" = 201 ] || { echo "❌ $CODE $OUT"; exit 1; }
echo "   ✅ profil financier enregistré"

# 5 — Retirement calculation
say "POST /calculator/retirement"
OUT=$(req POST /calculator/retirement '{"currentAge":35,"grossAnnualIncome":9500000,"currentPillar2Capital":5000000,"annualPillar2Contribution":600000,"currentPillar3aBalance":1000000,"annualPillar3aContribution":500000}')
CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] || { echo "❌ $CODE $OUT"; exit 1; }
echo "   ✅ projection OK (taux de remplacement $(echo "$OUT" | jqget "d['replacementRate']") %)"

# 6 — Upload document (minimal PDF) → validates the service role key (Storage)
say "POST /documents (upload PDF → Supabase Storage)"
PDF=$(mktemp /tmp/smoke-XXXX.pdf)
printf '%%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\ntrailer<</Root 1 0 R>>\n%%%%EOF\n' > "$PDF"
OUT=$(curl -sS -X POST -H "$AUTH" -F "type=BVG_STATEMENT" -F "file=@$PDF;type=application/pdf" -w $'\n%{http_code}' "$API/documents")
CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
rm -f "$PDF"
[ "$CODE" = 200 ] || [ "$CODE" = 201 ] || { echo "❌ $CODE $OUT"; exit 1; }
echo "   ✅ upload Storage OK (service role key valide)"

# 7 — Delete account (cleanup + service role on the auth admin side)
say "DELETE /users/me"
OUT=$(req DELETE /users/me); CODE="${OUT##*$'\n'}"; OUT="${OUT%$'\n'*}"
[ "$CODE" = 200 ] || [ "$CODE" = 204 ] || { echo "❌ $CODE $OUT"; exit 1; }
TOKEN="" # deletion succeeded → the trap EXIT has nothing left to do
echo "   ✅ compte supprimé (backend + auth)"

echo
echo "🎉 Smoke test complet : register → profil → calcul → documents → suppression — tout est vert."
