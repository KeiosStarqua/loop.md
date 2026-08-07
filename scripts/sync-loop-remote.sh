#!/usr/bin/env bash
# Fetch latest sync-loop.sh (+ template) from loop.md on GitHub, then run sync.
set -euo pipefail

LOOP_CONFIG_RAW_BASE="${LOOP_CONFIG_RAW_BASE:-https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main}"
SYNC_LOOP_SCRIPT_URL="${SYNC_LOOP_SCRIPT_URL:-${LOOP_CONFIG_RAW_BASE}/scripts/sync-loop.sh}"
CACHE="${LOOP_CONFIG_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/loop-config}"

die() { echo "error: $*" >&2; exit 1; }

fetch() {
  local url="$1"
  local dest="$2"
  curl -fsSL "$url" -o "$dest" || die "không tải được: $url"
}

mkdir -p "$CACHE/scripts"
fetch "$SYNC_LOOP_SCRIPT_URL" "$CACHE/scripts/sync-loop.sh"
fetch "${LOOP_CONFIG_RAW_BASE}/LOOP.mdc" "$CACHE/LOOP.mdc"
fetch "${LOOP_CONFIG_RAW_BASE}/loop.env.example" "$CACHE/loop.env.example"
chmod +x "$CACHE/scripts/sync-loop.sh"

exec "$CACHE/scripts/sync-loop.sh" "$@"
