#!/usr/bin/env bash
# Sinh LOOP.mdc từ LOOP.md: cùng nội dung, thêm frontmatter Cursor rule.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="${ROOT}/LOOP.md"
DEST="${ROOT}/LOOP.mdc"

usage() {
  cat <<'EOF'
Usage:
  gen-loop-mdc.sh [--check]

  Mặc định: ghi LOOP.mdc = frontmatter Cursor + nội dung LOOP.md
            (--- / alwaysApply: true / ---). Không đổi LOOP.md.

  --check     thoát 1 nếu LOOP.mdc lệch so với kết quả sinh ra (không ghi file)
EOF
}

die() { echo "error: $*" >&2; exit 1; }

render() {
  printf '%s\n' '---' 'alwaysApply: true' '---' ''
  cat "$SRC"
}

main() {
  local check=0
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    --check) check=1 ;;
    "") ;;
    *) die "flag không rõ: $1" ;;
  esac

  [[ -f "$SRC" ]] || die "không tìm thấy nguồn: $SRC"

  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  render > "$tmp"

  if [[ -f "$DEST" ]] && cmp -s "$tmp" "$DEST"; then
    if ((check)); then
      echo "LOOP.mdc khớp LOOP.md"
    else
      echo "LOOP.mdc đã khớp LOOP.md (không ghi lại)"
    fi
    exit 0
  fi

  if ((check)); then
    echo "error: LOOP.mdc lệch LOOP.md — chạy scripts/gen-loop-mdc.sh" >&2
    exit 1
  fi

  mv "$tmp" "$DEST"
  trap - RETURN
  echo "đã ghi: $DEST"
}

main "$@"
