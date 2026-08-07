#!/usr/bin/env bash
# Copy LOOP.mdc template vào repo đích và thay REPLACE_* từ .cursor/loop.env
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="${CONFIG_ROOT}/LOOP.mdc"
EXAMPLE_ENV="${CONFIG_ROOT}/loop.env.example"

PLACEHOLDERS=(
  REPLACE_LINEAR_OWNER_DISPLAY_NAME
  REPLACE_LINEAR_WORKSPACE
  REPLACE_LINEAR_PROJECT_NAME
  REPLACE_LINEAR_PROJECT_URL
  REPLACE_LINEAR_PROJECT_ID
)

usage() {
  cat <<'EOF'
Usage:
  sync-loop.sh [--init] [TARGET_REPO]

  Không có flag: copy LOOP.mdc → TARGET/.cursor/rules/LOOP.mdc
                và thay REPLACE_* bằng giá trị trong TARGET/.cursor/loop.env

  --init        tạo TARGET/.cursor/loop.env từ loop.env.example (không ghi đè)

TARGET_REPO mặc định: thư mục hiện tại (.)
EOF
}

die() { echo "error: $*" >&2; exit 1; }

escape_sed() {
  # Escape \, /, &, và newline cho sed replacement
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

load_env_file() {
  local env_file="$1"
  local line key value
  declare -gA LOOP_VARS=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      # Bỏ quote bao quanh nếu có
      if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
        value="${BASH_REMATCH[1]}"
      fi
      LOOP_VARS["$key"]="$value"
    else
      die "dòng không hợp lệ trong $env_file: $line"
    fi
  done < "$env_file"
}

require_placeholders() {
  local missing=()
  local key
  for key in "${PLACEHOLDERS[@]}"; do
    if [[ -z "${LOOP_VARS[$key]+x}" || -z "${LOOP_VARS[$key]}" ]]; then
      missing+=("$key")
    fi
  done
  if ((${#missing[@]})); then
    die "thiếu giá trị trong .cursor/loop.env: ${missing[*]}"
  fi
}

strip_checklist() {
  # Bỏ section checklist REPLACE (chỉ cần trên template)
  awk '
    /^### Checklist REPLACE/ { skip=1; next }
    skip && /^### / { skip=0 }
    !skip { print }
  '
}

cmd_init() {
  local target="$1"
  local dest="${target}/.cursor/loop.env"
  mkdir -p "${target}/.cursor"
  if [[ -f "$dest" ]]; then
    echo "đã có: $dest (không ghi đè)"
    return 0
  fi
  cp "$EXAMPLE_ENV" "$dest"
  echo "đã tạo: $dest — hãy điền giá trị Linear của repo"
}

cmd_sync() {
  local target="$1"
  local env_file="${target}/.cursor/loop.env"
  local out_dir="${target}/.cursor/rules"
  local out_file="${out_dir}/LOOP.mdc"
  local key tmp

  [[ -f "$TEMPLATE" ]] || die "không tìm thấy template: $TEMPLATE"
  [[ -f "$env_file" ]] || die "chưa có $env_file — chạy: $0 --init \"$target\""

  load_env_file "$env_file"
  require_placeholders

  mkdir -p "$out_dir"
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  # Copy template, bỏ checklist, rồi thay từng placeholder
  strip_checklist < "$TEMPLATE" > "$tmp"

  for key in "${PLACEHOLDERS[@]}"; do
    local escaped
    escaped="$(escape_sed "${LOOP_VARS[$key]}")"
    sed -i "s/${key}/${escaped}/g" "$tmp"
  done

  # Còn sót REPLACE_ → lỗi
  if grep -qE 'REPLACE_LINEAR_[A-Z_]+' "$tmp"; then
    echo "error: vẫn còn placeholder chưa thay:" >&2
    grep -nE 'REPLACE_LINEAR_[A-Z_]+' "$tmp" >&2 || true
    exit 1
  fi

  mv "$tmp" "$out_file"
  trap - RETURN
  echo "đã ghi: $out_file"
  for key in "${PLACEHOLDERS[@]}"; do
    printf '  %s=%s\n' "$key" "${LOOP_VARS[$key]}"
  done
}

main() {
  local init=0
  local target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --init) init=1; shift ;;
      -*) die "flag không rõ: $1" ;;
      *) target="$1"; shift ;;
    esac
  done

  target="$(cd "${target:-.}" && pwd)"
  [[ -d "$target" ]] || die "không phải thư mục: $target"

  if ((init)); then
    cmd_init "$target"
  else
    cmd_sync "$target"
  fi
}

main "$@"
