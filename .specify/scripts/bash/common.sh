#!/usr/bin/env bash
# common.sh - Shared utilities for all speckit scripts

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get the next feature number by scanning specs/ (all specs are flat: specs/NNN-feature-name/)
get_next_feature_number() {
  local specs_dir="specs"
  if [ ! -d "$specs_dir" ]; then
    echo "001"
    return
  fi

  local max=0
  for dir in "$specs_dir"/*/; do
    local name
    name=$(basename "$dir")
    local num
    num=$(echo "$name" | grep -oE '^[0-9]+' || echo "0")
    if [ "$((10#$num))" -gt "$max" ]; then
      max=$((10#$num))
    fi
  done

  printf "%03d" $((max + 1))
}

# Slugify a string: lowercase, replace spaces with dashes, remove special chars
slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g'
}

# Escape a string for use as a sed replacement (handles /, &, \)
escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&/\]/\\&/g'
}

# Decide the plan/tasks layout from the spec.md Owner header (constitution Article V / XIII).
#   `> **Owner**: @bob`                              -> single (plan.md + tasks.md)
#   `> **Owner**: @alice (frontend), @bob (backend)` -> split  (plus plan-/tasks-frontend|backend.md)
# Prints "single" or "split"; logs and returns 1 when Owner is unfilled or malformed.
# Specs written before the Owner field existed (no Owner line) are treated as single.
get_owner_mode() {
  local spec_file="$1"
  local line value entries entry_count labels label_count

  line=$(grep -m1 '^> \*\*Owner\*\*:' "$spec_file" || true)
  if [ -z "$line" ]; then
    echo single
    return 0
  fi

  value=$(printf '%s' "$line" | sed -e 's/<!--.*-->//' -e 's/^> \*\*Owner\*\*:[[:space:]]*//' -e 's/、/,/g' -e 's/[[:space:]]*$//')
  if [ -z "$value" ] || [ "$value" = "[OWNER]" ]; then
    log_error "spec.md 的 Owner 尚未填寫"
    return 1
  fi

  entries=$(printf '%s' "$value" | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' || true)
  entry_count=$(printf '%s\n' "$entries" | grep -c . || true)
  labels=$(printf '%s\n' "$entries" | grep -oE '\([^)]*\)' | tr -d '()' | sort || true)
  label_count=$(printf '%s\n' "$labels" | grep -c . || true)

  if [ "$label_count" -eq 0 ]; then
    if [ "$entry_count" -eq 1 ]; then
      echo single
      return 0
    fi
    log_error "Owner 有多人時必須是前後端各一人並標註：@alice (frontend), @bob (backend)（目前：${value}）"
    return 1
  fi

  if [ "$entry_count" -eq 2 ] && [ "$label_count" -eq 2 ] && [ "$(echo $labels)" = "backend frontend" ]; then
    echo split
    return 0
  fi
  log_error "拆檔時 Owner 必須恰好兩人，分別標註 (frontend) 與 (backend)（目前：${value}）"
  return 1
}

# Print task lines of a tasks file: `-`/`*` list items starting with a status checkbox
# (constitution Article XIII), skipping anything inside ``` code blocks.
task_lines() {
  awk '
    /^[[:space:]]*```/ { in_code = !in_code; next }
    !in_code && /^[[:space:]]*[-*] \[[ ~rcx]\]/ { print }
  ' "$1"
}

# Print the layout the existing task lists were generated with: none | single | split
detect_tasks_layout() {
  local dir="$1"
  if [ -f "$dir/tasks-frontend.md" ] || [ -f "$dir/tasks-backend.md" ]; then
    echo split
  elif [ -f "$dir/tasks.md" ] && [ -n "$(task_lines "$dir/tasks.md")" ]; then
    echo single
  else
    echo none
  fi
}

# Check if git is available and we're in a git repo
check_git() {
  if ! command -v git &>/dev/null; then
    log_warn "git not found — skipping branch operations"
    return 1
  fi
  if ! git rev-parse --git-dir &>/dev/null; then
    log_warn "Not in a git repository — skipping branch operations"
    return 1
  fi
  return 0
}
