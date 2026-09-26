#!/usr/bin/env bash
# Copy LOOP.mdc template vào repo đích và thay REPLACE_* từ .cursor/loop.jsonc
# (vẫn đọc .cursor/loop.env nếu chưa có loop.jsonc — một project).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="${CONFIG_ROOT}/LOOP.mdc"
EXAMPLE_CONFIG="${CONFIG_ROOT}/loop.jsonc.example"
PARSE_PY="${SCRIPT_DIR}/loop-jsonc.py"

PLACEHOLDERS=(
  REPLACE_LINEAR_OWNER_DISPLAY_NAME
  REPLACE_LINEAR_WORKSPACE
  REPLACE_LOOP_FORCE_MERGE_PR
  REPLACE_LINEAR_DEFAULT_PROJECT_NAME
  REPLACE_LINEAR_PROJECT_NAMES
  REPLACE_LINEAR_PROJECTS_TABLE
)

usage() {
  cat <<'EOF'
Usage:
  sync-loop.sh [--init] [TARGET_REPO]
  sync-loop.sh --setup --owner NAME --workspace SLUG \
               --project-name NAME --project-url URL --project-id ID \
               [--project-name NAME --project-url URL --project-id ID ...] \
               [--force-merge true|false] [--force] [TARGET_REPO]

  Không có flag: copy LOOP.mdc → TARGET/.cursor/rules/LOOP.mdc
                và thay REPLACE_* bằng giá trị trong TARGET/.cursor/loop.jsonc.
                Nếu chưa có loop.jsonc nhưng có loop.env → đọc loop.env (một project).
                Nếu chưa có cả hai → tự tạo loop.jsonc từ loop.jsonc.example
                rồi sync ngay (không lỗi). Sửa lại loop.jsonc rồi chạy lần nữa
                nếu giá trị mặc định không đúng cho repo này.

  --init        chỉ tạo TARGET/.cursor/loop.jsonc từ loop.jsonc.example (không ghi đè,
                không sync). Nếu đã có loop.env mà chưa có loop.jsonc thì không tạo,
                vì loop.jsonc được ưu tiên và sẽ che loop.env.

  --setup       tạo loop.jsonc từ flag (nếu chưa có, hoặc ghi đè nếu kèm --force)
                rồi sync ngay. Lặp bộ --project-name/--project-url/--project-id
                cho mỗi Linear project. Project đầu tiên là mặc định.
                loop.jsonc hoặc loop.env đã có sẵn thì giữ nguyên (bỏ qua flag)
                trừ khi --force.

  --force-merge true|false
                chỉ cùng --setup. Mặc định true.

  --force       chỉ có tác dụng cùng --setup: ghi đè loop.jsonc đã có

TARGET_REPO mặc định: thư mục hiện tại (.)
EOF
}

die() { echo "error: $*" >&2; exit 1; }

escape_sed() {
  # Escape \, /, & trên từng dòng, rồi nối newline thành \n cho sed replacement.
  # Phải escape trước khi gộp dòng: nếu gộp trước, các dòng sau dấu / trong URL
  # không được escape và sed báo "unknown option to s".
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

require_python() {
  command -v python3 >/dev/null 2>&1 || die "cần python3 để đọc loop.jsonc"
  [[ -f "$PARSE_PY" ]] || die "không tìm thấy: $PARSE_PY"
}

load_config() {
  local file="$1"
  local emitted
  require_python
  emitted="$(python3 "$PARSE_PY" emit "$file")"
  # shellcheck disable=SC2163
  eval "$emitted"
}

cmd_init() {
  local target="$1"
  local dest="${target}/.cursor/loop.jsonc"
  local legacy="${target}/.cursor/loop.env"
  mkdir -p "${target}/.cursor"
  if [[ -f "$dest" ]]; then
    echo "đã có: $dest (không ghi đè)"
    return 0
  fi
  if [[ -f "$legacy" ]]; then
    echo "đã có: $legacy — không tạo loop.jsonc từ mẫu, vì loop.jsonc được ưu tiên và sẽ che loop.env."
    echo "  Tạo .cursor/loop.jsonc bằng tay (mẫu loop.jsonc.example), hoặc chạy --setup --force."
    return 0
  fi
  [[ -f "$EXAMPLE_CONFIG" ]] || die "không tìm thấy mẫu: $EXAMPLE_CONFIG"
  cp "$EXAMPLE_CONFIG" "$dest"
  echo "đã tạo: $dest — hãy điền project Linear của repo"
}

cmd_setup() {
  local target="$1"
  local force="$2"
  local dest="${target}/.cursor/loop.jsonc"
  local legacy="${target}/.cursor/loop.env"
  local -a write_args=()
  local index

  if [[ -f "$dest" && "$force" != 1 ]]; then
    echo "đã có: $dest (giữ nguyên, dùng --force để ghi đè)"
  elif [[ -f "$legacy" && ! -f "$dest" && "$force" != 1 ]]; then
    echo "đã có: $legacy (giữ nguyên, dùng --force để ghi loop.jsonc)"
  else
    if [[ -z "${SETUP_OWNER:-}" || -z "${SETUP_WORKSPACE:-}" ]]; then
      die "thiếu flag cho --setup: --owner và --workspace"
    fi
    if ((${#PROJECT_NAMES[@]} == 0)); then
      die "thiếu flag cho --setup: --project-name, --project-url, --project-id"
    fi
    if ((${#PROJECT_NAMES[@]} != ${#PROJECT_URLS[@]} || ${#PROJECT_NAMES[@]} != ${#PROJECT_IDS[@]})); then
      die "--project-name, --project-url và --project-id phải đi thành bộ và cùng số lượng"
    fi

    mkdir -p "${target}/.cursor"
    require_python
    write_args=(
      write
      --dest "$dest"
      --owner "$SETUP_OWNER"
      --workspace "$SETUP_WORKSPACE"
      --force-merge "${SETUP_FORCE_MERGE:-true}"
    )
    for index in "${!PROJECT_NAMES[@]}"; do
      write_args+=(--project "${PROJECT_NAMES[$index]}" "${PROJECT_URLS[$index]}" "${PROJECT_IDS[$index]}")
    done
    python3 "$PARSE_PY" "${write_args[@]}"
    echo "đã tạo: $dest"
    if [[ -f "$legacy" ]]; then
      echo "  loop.jsonc được ưu tiên; loop.env không còn được đọc khi sync"
    fi
  fi

  cmd_sync "$target"
}

cmd_sync() {
  local target="$1"
  local jsonc="${target}/.cursor/loop.jsonc"
  local legacy="${target}/.cursor/loop.env"
  local config_file=""
  local out_dir="${target}/.cursor/rules"
  local out_file="${out_dir}/LOOP.mdc"
  local key tmp

  [[ -f "$TEMPLATE" ]] || die "không tìm thấy template: $TEMPLATE"

  if [[ -f "$jsonc" ]]; then
    config_file="$jsonc"
  elif [[ -f "$legacy" ]]; then
    config_file="$legacy"
    echo "đang đọc $legacy (một project). Nhiều project: tạo .cursor/loop.jsonc — file đó được ưu tiên hơn loop.env."
  else
    cmd_init "$target"
    config_file="$jsonc"
    echo "  (dùng giá trị mặc định trong loop.jsonc.example — sửa $config_file rồi chạy lại nếu không đúng cho repo này)"
  fi

  [[ -f "$config_file" ]] || die "không có file cấu hình: $jsonc"
  load_config "$config_file"

  declare -A LOOP_VARS=(
    [REPLACE_LINEAR_OWNER_DISPLAY_NAME]="$LOOP_OWNER"
    [REPLACE_LINEAR_WORKSPACE]="$LOOP_WORKSPACE"
    [REPLACE_LOOP_FORCE_MERGE_PR]="$LOOP_FORCE_MERGE"
    [REPLACE_LINEAR_DEFAULT_PROJECT_NAME]="$LOOP_DEFAULT_PROJECT_NAME"
    [REPLACE_LINEAR_PROJECT_NAMES]="$LOOP_PROJECT_NAMES"
    [REPLACE_LINEAR_PROJECTS_TABLE]="$LOOP_PROJECTS_TABLE"
  )

  mkdir -p "$out_dir"
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  awk '
    /^### Checklist REPLACE/ { skip=1; next }
    skip && /^### / { skip=0 }
    !skip { print }
  ' "$TEMPLATE" > "$tmp"

  for key in "${PLACEHOLDERS[@]}"; do
    local escaped
    escaped="$(escape_sed "${LOOP_VARS[$key]}")"
    sed -i "s/${key}/${escaped}/g" "$tmp"
  done

  if grep -qE 'REPLACE_(LINEAR|LOOP)_[A-Z0-9_]+' "$tmp"; then
    echo "error: vẫn còn placeholder chưa thay:" >&2
    grep -nE 'REPLACE_(LINEAR|LOOP)_[A-Z0-9_]+' "$tmp" >&2 || true
    exit 1
  fi

  mv "$tmp" "$out_file"
  trap - RETURN
  echo "đã ghi: $out_file"
  printf '  ownerDisplayName=%s\n' "$LOOP_OWNER"
  printf '  workspace=%s\n' "$LOOP_WORKSPACE"
  printf '  forceMergePr=%s\n' "$LOOP_FORCE_MERGE"
  printf '  projects=%s\n' "$LOOP_PROJECT_NAMES"
  printf '  default=%s\n' "$LOOP_DEFAULT_PROJECT_NAME"
}

main() {
  local init=0
  local setup=0
  local force=0
  local force_merge_set=0
  local target=""
  SETUP_OWNER=""
  SETUP_WORKSPACE=""
  SETUP_FORCE_MERGE="true"
  PROJECT_NAMES=()
  PROJECT_URLS=()
  PROJECT_IDS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) usage; exit 0 ;;
      --init) init=1; shift ;;
      --setup) setup=1; shift ;;
      --force) force=1; shift ;;
      --owner) SETUP_OWNER="$2"; shift 2 ;;
      --workspace) SETUP_WORKSPACE="$2"; shift 2 ;;
      --project-name) PROJECT_NAMES+=("$2"); shift 2 ;;
      --project-url) PROJECT_URLS+=("$2"); shift 2 ;;
      --project-id) PROJECT_IDS+=("$2"); shift 2 ;;
      --force-merge) SETUP_FORCE_MERGE="$2"; force_merge_set=1; shift 2 ;;
      -*) die "flag không rõ: $1" ;;
      *) target="$1"; shift ;;
    esac
  done

  if ((force_merge_set && !setup)); then
    die "--force-merge chỉ dùng cùng --setup"
  fi
  if ((force && !setup)); then
    die "--force chỉ dùng cùng --setup"
  fi

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
