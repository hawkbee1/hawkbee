#!/usr/bin/env bash
# Call the local Appwrite REST API (project hawkbee) with the tooling key.
#
#   aw.sh [--as <userId>] [-q '<query json>']... [-o <file>] <METHOD> <path> [<json body>]
#
#   aw.sh GET /tablesdb/hawkbee/tables
#   aw.sh -q '{"method":"limit","values":[5]}' GET /tablesdb/hawkbee/tables/bt_wars/rows
#   aw.sh POST /functions/ping/executions '{"body":"","async":false}'
#   aw.sh --as <userId> GET /account
#   aw.sh -o <scratchpad>/log.bin GET /storage/buckets/<b>/files/<f>/download
#
# The key is read from the owner's env file and never printed or put on a
# command line. --as makes a short-lived JWT for that user and calls with it
# instead of the key, so the call has exactly the user's rights.
# The response goes to stdout as JSON with password hashes, secrets and JWTs
# replaced by "<redacted>"; "HTTP <code>" goes to stderr. Exit 1 on HTTP >= 400.
#
# Overrides: APPWRITE_ENV_FILE, APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, AW_TIMEOUT.
set -euo pipefail

env_file=${APPWRITE_ENV_FILE:-/volume/soul/dockers/appwrite/appwrite-local.env}
endpoint=${APPWRITE_ENDPOINT:-http://appwrite-traefik/v1}
project=${APPWRITE_PROJECT_ID:-hawkbee}
timeout=${AW_TIMEOUT:-120}

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

as_user=
out=
queries=()
while [ $# -gt 0 ]; do
  case $1 in
    --as) as_user=${2:?--as needs a user ID}; shift 2 ;;
    -q) queries+=(--data-urlencode "queries[]=${2:?-q needs a query}"); shift 2 ;;
    -o) out=${2:?-o needs a file}; shift 2 ;;
    -h | --help) usage ;;
    *) break ;;
  esac
done
[ $# -ge 2 ] || usage
method=$(printf %s "$1" | tr '[:lower:]' '[:upper:]')
path=$2
body=${3:-}
case $path in /*) ;; *) path=/$path ;; esac

[ -r "$env_file" ] || { echo "aw: cannot read $env_file (holds LOCAL_TOOLING_API_KEY)" >&2; exit 2; }
key=$(set -a && . "$env_file" >/dev/null 2>&1 && printf %s "${LOCAL_TOOLING_API_KEY:-}")
[ -n "$key" ] || { echo "aw: LOCAL_TOOLING_API_KEY is not set in $env_file" >&2; exit 2; }

# curl reads the secret header from a file descriptor, so it never shows in `ps`.
# Prints the body, then the status code on the last line.
request() { # <auth header> <method> <path> <body> <out file> [query args...]
  local auth=$1 m=$2 p=$3 b=$4 o=$5
  shift 5
  local args=(-sS -m "$timeout" -w '\n%{http_code}' -H "X-Appwrite-Project: $project")
  [ -n "$o" ] && args+=(-o "$o")
  if [ "$m" = GET ]; then
    args+=(-G "$@")
  else
    args+=(-X "$m" -H 'Content-Type: application/json')
    [ -n "$b" ] && args+=(--data-binary "$b")
  fi
  curl "${args[@]}" -H @<(printf '%s\n' "$auth") "$endpoint$p" || true
}

split() { # sets resp_body and resp_code from request output
  resp_code=${1##*$'\n'}
  resp_body=${1%$'\n'*}
  case $resp_code in
    [1-5][0-9][0-9]) ;;
    *) echo "aw: no answer from $endpoint (is the local Appwrite up?)" >&2; exit 1 ;;
  esac
}

auth="X-Appwrite-Key: $key"
if [ -n "$as_user" ]; then
  split "$(request "$auth" POST "/users/$as_user/jwts" '{"duration":900}' '')"
  if [ "$resp_code" -ge 400 ]; then
    echo "aw: could not make a JWT for user $as_user (HTTP $resp_code)" >&2
    printf '%s\n' "$resp_body" >&2
    exit 1
  fi
  jwt=$(printf '%s' "$resp_body" | jq -r '.jwt // empty')
  [ -n "$jwt" ] || { echo "aw: no JWT in the answer for user $as_user" >&2; exit 1; }
  auth="X-Appwrite-JWT: $jwt"
fi

split "$(request "$auth" "$method" "$path" "$body" "$out" ${queries[@]+"${queries[@]}"})"
if [ -n "$out" ]; then
  echo "aw: body saved to $out ($(wc -c < "$out") bytes)" >&2
  if [ "$resp_code" -ge 400 ]; then head -c 1000 "$out" >&2; echo >&2; fi
fi

redact='walk(if type == "object" then with_entries(
  if (.key | test("^(password|hash|hashOptions|secret|jwt|providerAccessToken|providerRefreshToken)$"))
     and .value != "" and .value != null and .value != {}
  then .value = "<redacted>" else . end) else . end)'
if [ -z "$resp_body" ]; then
  :
elif printf '%s' "$resp_body" | jq -e . >/dev/null 2>&1; then
  printf '%s' "$resp_body" | jq "$redact"
elif printf '%s' "$resp_body" | grep -qi '<html'; then
  type=$(printf '%s' "$resp_body" | grep -o "class='type'>[^<]*" | head -1 | cut -d'>' -f2)
  echo "aw: HTML page instead of JSON (${type:-no error type}): check the path against the API reference"
else
  printf '%s\n' "$resp_body" | cut -c1-2000
fi
echo "HTTP $resp_code" >&2
[ "$resp_code" -lt 400 ]
