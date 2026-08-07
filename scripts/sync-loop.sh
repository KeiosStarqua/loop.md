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
  sync-loop.sh --setup --owner NAME --workspace SLUG --project-name NAME \
               --project-url URL --project-id ID [--force] [TARGET_REPO]

  Không có flag: copy LOOP.mdc → TARGET/.cursor/rules/LOOP.mdc
                và thay REPLACE_* bằng giá trị trong TARGET/.cursor/loop.env.
                Nếu TARGET/.cursor/loop.env chưa có → tự tạo từ loop.env.example
                rồi sync ngay (không lỗi). Sửa lại loop.env rồi chạy lần nữa
                nếu giá trị mặc định không đúng cho repo này.

  --init        chỉ tạo TARGET/.cursor/loop.env từ loop.env.example (không ghi đè,
                không sync) — dùng khi muốn sửa trước khi sync

  --setup       làm cả 3 bước trong 1 lệnh: tạo loop.env từ 5 flag Linear
                (nếu chưa có, hoặc ghi đè nếu kèm --force) rồi sync ngay.
                Thiếu flag nào mà loop.env chưa có → báo lỗi rõ flag đó.
                loop.env đã có sẵn thì giữ nguyên (bỏ qua các flag) trừ khi --force.

  --force       chỉ có tác dụng cùng --setup: ghi đè loop.env đã có

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

cmd_setup() {
  local target="$1"
  local force="$2"
  local dest="${target}/.cursor/loop.env"
  local key missing=()

  if [[ -f "$dest" && "$force" != 1 ]]; then
    echo "đã có: $dest (giữ nguyên, dùng --force để ghi đè)"
  else
    for key in "${PLACEHOLDERS[@]}"; do
      if [[ -z "${SETUP_VALUES[$key]+x}" || -z "${SETUP_VALUES[$key]}" ]]; then
        missing+=("$key")
      fi
    done
    if ((${#missing[@]})); then
      die "thiếu flag cho --setup (loop.env chưa tồn tại): ${missing[*]}"
    fi

    mkdir -p "${target}/.cursor"
    {
      echo "# Giá trị Linear cho repo này — tạo bởi sync-loop.sh --setup"
      for key in "${PLACEHOLDERS[@]}"; do
        printf '%s=%s\n' "$key" "${SETUP_VALUES[$key]}"
      done
    } > "$dest"
    echo "đã tạo: $dest"
  fi

  cmd_sync "$target"
}

cmd_sync() {
  local target="$1"
  local env_file="${target}/.cursor/loop.env"
  local out_dir="${target}/.cursor/rules"
  local out_file="${out_dir}/LOOP.mdc"
  local key tmp

  [[ -f "$TEMPLATE" ]] || die "không tìm thấy template: $TEMPLATE"

  if [[ ! -f "$env_file" ]]; then
    cmd_init "$target"
    echo "  (dùng giá trị Linear mặc định trong loop.env.example — sửa $env_file rồi chạy lại nếu không đúng cho repo này)"
  fi

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
  local setup=0
  local force=0
  local target=""
  declare -gA SETUP_VALUES=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --init) init=1; shift ;;
      --setup) setup=1; shift ;;
      --force) force=1; shift ;;
      --owner) SETUP_VALUES[REPLACE_LINEAR_OWNER_DISPLAY_NAME]="$2"; shift 2 ;;
      --workspace) SETUP_VALUES[REPLACE_LINEAR_WORKSPACE]="$2"; shift 2 ;;
      --project-name) SETUP_VALUES[REPLACE_LINEAR_PROJECT_NAME]="$2"; shift 2 ;;
      --project-url) SETUP_VALUES[REPLACE_LINEAR_PROJECT_URL]="$2"; shift 2 ;;
      --project-id) SETUP_VALUES[REPLACE_LINEAR_PROJECT_ID]="$2"; shift 2 ;;
      -*) die "flag không rõ: $1" ;;
      *) target="$1"; shift ;;
    esac
  done

  target="$(cd "${target:-.}" && pwd)"
  [[ -d "$target" ]] || die "không phải thư mục: $target"

  if ((setup)); then
    cmd_setup "$target" "$force"
  elif ((init)); then
    cmd_init "$target"
  else
    cmd_sync "$target"
  fi
}

main "$@"
