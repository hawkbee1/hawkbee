#!/usr/bin/env bash
# Compare backend/appwrite.config.json with the local Appwrite before
# `appwrite push table|bucket --force`: --force skips the CLI's confirmations,
# so a table, column or index that exists only on the server would be deleted
# with its data, and a column whose type differs would be recreated.
#
#   schema_drift.sh [<appwrite.config.json>]
#
# Prints every difference. Exit 0: the push only adds. Exit 1: the server has
# something the config lacks, or a column type differs. Do not force that push.
set -euo pipefail

aw=$(cd "$(dirname "$0")" && pwd)/aw.sh
config=${1:-$(git rev-parse --show-toplevel)/backend/appwrite.config.json}
db=$(jq -r '.tablesDB[0]."$id"' "$config")
all='{"method":"limit","values":[5000]}'

server_tables=$("$aw" -q "$all" GET "/tablesdb/$db/tables" 2>/dev/null) &&
  server_buckets=$("$aw" -q "$all" GET /storage/buckets 2>/dev/null) ||
  { echo "drift: cannot read tables and buckets from the server (try aw.sh GET /health)" >&2; exit 2; }

report=$(jq -rn --slurpfile cfg "$config" --argjson st "$server_tables" --argjson sb "$server_buckets" '
  def ids(a): [a[] | ."$id"] | sort;
  def keys_of(a): [a[]? | .key] | sort;
  def only(a; b): a - b;
  $cfg[0] as $c
  | (ids($c.tables)) as $ct | (ids($st.tables)) as $stt
  | (ids($c.buckets // [])) as $cb | (ids($sb.buckets)) as $sbb
  | [ (only($stt; $ct)[] | "DELETE  table \(.) (server only)"),
      (only($ct; $stt)[] | "add     table \(.)"),
      (only($sbb; $cb)[] | "DELETE  bucket \(.) (server only)"),
      (only($cb; $sbb)[] | "add     bucket \(.)"),
      ( $c.tables[] as $t
        | ($st.tables[] | select(."$id" == $t."$id")) as $s
        | ( (only(keys_of($s.columns); keys_of($t.columns))[] | "DELETE  column \($t."$id").\(.) (server only)"),
            (only(keys_of($t.columns); keys_of($s.columns))[] | "add     column \($t."$id").\(.)"),
            (only(keys_of($s.indexes); keys_of($t.indexes))[] | "DELETE  index \($t."$id").\(.) (server only)"),
            (only(keys_of($t.indexes); keys_of($s.indexes))[] | "add     index \($t."$id").\(.)"),
            ( $t.columns[] as $col
              | ($s.columns[] | select(.key == $col.key)) as $sc
              | select($sc.type != $col.type)
              | "RETYPE  column \($t."$id").\($col.key): server \($sc.type), config \($col.type)" ) ) )
    ]
  | if length == 0 then "no difference: server and config match"
    else .[] end')
printf '%s\n' "$report"
! grep -qE '^(DELETE|RETYPE) ' <<<"$report"
