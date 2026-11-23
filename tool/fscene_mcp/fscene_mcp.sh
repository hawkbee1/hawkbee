#!/usr/bin/env bash
# Starts the headless flutter_scene MCP server (fscene_mcp.dart) on stdio.
# Registered in .mcp.json as "fscene". By hand: tool/fscene_mcp/fscene_mcp.sh [scene.fscene]
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
config="$root/packages/flutter_scene/.dart_tool/package_config.json"
if [[ ! -f "$config" ]]; then
  echo "fscene_mcp: run 'flutter pub get' in packages/flutter_scene first" >&2
  exit 1
fi
exec dart --packages="$config" "$root/tool/fscene_mcp/fscene_mcp.dart" "$@"
