#!/usr/bin/env bash
# check-prerequisites.sh - Validates environment before implementation begins
# Usage: ./check-prerequisites.sh [branch-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SPECS_DIR="specs"
MEMORY_DIR=".specify/memory"

# Determine branch name
if [ -n "${1:-}" ]; then
  BRANCH_NAME="$1"
elif check_git; then
  BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
else
  log_error "Cannot determine branch name."
  exit 1
fi

SPEC_DIR="${SPECS_DIR}/${BRANCH_NAME}"
ERRORS=0

# fail <message> — log an error and count it (ERRORS=$((...)) keeps set -e from exiting on 0)
fail() {
  log_error "$*"
  ERRORS=$((ERRORS + 1))
}

# check_task_ids <file> <id-regex> <id-label> — every task line carries a unique id of the expected form
check_task_ids() {
  local file="$1" id_re="$2" id_label="$3" name lines count bad dups
  name=$(basename "$file")
  lines=$(task_lines "$file")
  count=$(printf '%s\n' "$lines" | grep -c . || true)

  if [ "$count" -eq 0 ]; then
    fail "$name 沒有任何任務"
    return
  fi

  bad=$(printf '%s\n' "$lines" | grep -vE "\*\*${id_re}\*\*" || true)
  if [ -n "$bad" ]; then
    fail "$name 有任務缺少 ${id_label} 編號（或編號格式不符）："
    printf '%s\n' "$bad" | sed 's/^/    /' >&2
  fi

  dups=$(printf '%s\n' "$lines" | grep -oE "\*\*${id_re}\*\*" | sort | uniq -d | tr -d '*' || true)
  if [ -n "$dups" ]; then
    fail "$name 任務編號重複：$(echo $dups)"
  fi

  if [ -z "$bad" ] && [ -z "$dups" ]; then
    log_success "$name found ($count tasks)"
  fi
}

# check_filled <file> — exists and no longer a raw template
check_filled() {
  local file="$1" name
  name=$(basename "$file")
  if [ ! -f "$file" ]; then
    fail "$name not found in $SPEC_DIR — run /speckit-plan"
  elif grep -q '\[FEATURE_TITLE\]' "$file"; then
    fail "$name still contains template placeholders"
  else
    log_success "$name found and filled"
  fi
}

log_info "Checking prerequisites for: $BRANCH_NAME"
echo ""

# 1. Check constitution exists
echo "--- Constitution ---"
if [ -f "$MEMORY_DIR/constitution.md" ]; then
  log_success "constitution.md found"
else
  fail "constitution.md not found at $MEMORY_DIR/constitution.md"
fi

# 2. Check spec.md exists, is filled, and has a valid Owner
echo ""
echo "--- Specification ---"
MODE=""
if [ -f "$SPEC_DIR/spec.md" ]; then
  if grep -q '\[NEEDS CLARIFICATION\]' "$SPEC_DIR/spec.md"; then
    log_warn "spec.md has unresolved [NEEDS CLARIFICATION] markers — resolve before implementing"
  fi
  if grep -q '\[FEATURE_TITLE\]' "$SPEC_DIR/spec.md"; then
    fail "spec.md still contains template placeholders"
  else
    log_success "spec.md found and filled"
  fi
  if MODE=$(get_owner_mode "$SPEC_DIR/spec.md"); then
    log_success "Layout from Owner: $MODE"
  else
    MODE=""
    ERRORS=$((ERRORS + 1))
  fi
else
  fail "spec.md not found in $SPEC_DIR"
fi

# 3. Check plan files match the layout
echo ""
echo "--- Plan ---"
check_filled "$SPEC_DIR/plan.md"
if [ "$MODE" = split ]; then
  check_filled "$SPEC_DIR/plan-frontend.md"
  check_filled "$SPEC_DIR/plan-backend.md"
elif [ "$MODE" = single ]; then
  for side in frontend backend; do
    if [ -f "$SPEC_DIR/plan-${side}.md" ]; then
      fail "Owner 為一人（不拆檔），但 plan-${side}.md 存在 — 併回 plan.md 後刪除（憲法 Article V）"
    fi
  done
fi

# 4. Check task lists match the layout
echo ""
echo "--- Tasks ---"
LAYOUT=$(detect_tasks_layout "$SPEC_DIR")
if [ ! -f "$SPEC_DIR/tasks.md" ]; then
  fail "tasks.md not found in $SPEC_DIR — run /speckit-tasks first"
elif [ -n "$MODE" ] && [ "$LAYOUT" != none ] && [ "$LAYOUT" != "$MODE" ]; then
  fail "任務清單為「${LAYOUT}」格式，但 Owner 對應「${MODE}」— 任務產出後不得轉換；需要時另開新 spec 並以 DependsOn 指向本 spec（憲法 Article XIII）"
elif [ "$MODE" = single ]; then
  check_task_ids "$SPEC_DIR/tasks.md" 'TASK-[0-9]{3}[a-z]?' 'TASK-NNN'
elif [ "$MODE" = split ]; then
  if [ -n "$(task_lines "$SPEC_DIR/tasks.md")" ]; then
    fail "tasks.md 是總覽，不得含勾選任務 — 請移到 tasks-frontend.md／tasks-backend.md（憲法 Article XIII）"
  else
    log_success "tasks.md (overview) found"
  fi
  for side in frontend backend; do
    if [ "$side" = frontend ]; then prefix=FE; else prefix=BE; fi
    if [ -f "$SPEC_DIR/tasks-${side}.md" ]; then
      check_task_ids "$SPEC_DIR/tasks-${side}.md" "TASK-${prefix}-[0-9]{3}[a-z]?" "TASK-${prefix}-NNN"
    else
      fail "tasks-${side}.md not found in $SPEC_DIR — run /speckit-tasks"
    fi
  done
fi

# 5. Check git status
echo ""
echo "--- Git ---"
if check_git; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$CURRENT_BRANCH" = "$BRANCH_NAME" ]; then
    log_success "On correct branch: $BRANCH_NAME"
  else
    log_warn "Current branch ($CURRENT_BRANCH) != expected ($BRANCH_NAME)"
  fi

  UNCOMMITTED=$(git status --porcelain | wc -l | tr -d ' ')
  if [ "$UNCOMMITTED" -gt "0" ]; then
    log_warn "$UNCOMMITTED uncommitted changes in working tree"
  else
    log_success "Working tree clean"
  fi
fi

# Final result
echo ""
echo "================================"
if [ "$ERRORS" -eq 0 ]; then
  log_success "All prerequisites passed! Ready to implement."
  echo ""
  echo "Run /speckit-implement to begin."
else
  log_error "$ERRORS prerequisite(s) failed. Fix them before implementing."
  exit 1
fi
