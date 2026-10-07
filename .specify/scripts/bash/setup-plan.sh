#!/usr/bin/env bash
# setup-plan.sh - Scaffolds plan artifacts for the current feature branch
# Usage: ./setup-plan.sh [branch-name]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TEMPLATE_DIR=".specify/templates"
SPECS_DIR="specs"

# Determine branch name
if [ -n "${1:-}" ]; then
  BRANCH_NAME="$1"
elif check_git; then
  BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
else
  log_error "Cannot determine branch name. Pass it as an argument."
  exit 1
fi

SPEC_DIR="${SPECS_DIR}/${BRANCH_NAME}"

if [ ! -d "$SPEC_DIR" ]; then
  log_error "Spec directory not found: $SPEC_DIR"
  log_error "Run create-new-feature.sh first."
  exit 1
fi

if [ ! -f "$SPEC_DIR/spec.md" ]; then
  log_error "spec.md not found in $SPEC_DIR"
  exit 1
fi

log_info "Setting up plan artifacts for: $BRANCH_NAME"

TODAY=$(date +%Y-%m-%d)

# Extract feature title from spec.md (first h1 line, strip leading "# ")
FEATURE_TITLE=$(grep -m1 '^# ' "$SPEC_DIR/spec.md" | sed 's/^# //' || echo "$BRANCH_NAME")
SAFE_TITLE=$(escape_sed_replacement "$FEATURE_TITLE")
SAFE_BRANCH=$(escape_sed_replacement "$BRANCH_NAME")

# Decide the layout from the spec.md Owner (constitution Article V / XIII)
MODE=$(get_owner_mode "$SPEC_DIR/spec.md") || exit 1

# The layout is frozen once task lists exist
LAYOUT=$(detect_tasks_layout "$SPEC_DIR")
if [ "$LAYOUT" != none ] && [ "$LAYOUT" != "$MODE" ]; then
  log_error "任務清單已依「${LAYOUT}」產出，但 Owner 對應「${MODE}」— 任務產出後不得轉換拆檔方式"
  log_error "若需另一人負責另一邊，請另開新 spec 並以 DependsOn 指向本 spec（憲法 Article XIII）"
  exit 1
fi

# render_template <template> <output>
render_template() {
  local template="$1" output="$2"
  if [ -f "$output" ]; then
    log_warn "$(basename "$output") already exists — skipping"
    return
  fi
  sed \
    -e "s/\[FEATURE_TITLE\]/$SAFE_TITLE/g" \
    -e "s/NNN-feature-name/$SAFE_BRANCH/g" \
    -e "s/\[DATE\]/$TODAY/g" \
    "$template" > "$output"
  log_success "Created: $output"
}

if [ "$MODE" = split ]; then
  if [ -f "$SPEC_DIR/plan.md" ] && [ ! -f "$SPEC_DIR/plan-frontend.md" ] && [ ! -f "$SPEC_DIR/plan-backend.md" ]; then
    log_warn "plan.md 已存在但沒有分邊計劃 — 它可能是不拆檔的完整計劃，請確認內容後刪除並重新執行"
  fi
  render_template "$TEMPLATE_DIR/plan-shared-template.md" "$SPEC_DIR/plan.md"
  render_template "$TEMPLATE_DIR/plan-frontend-template.md" "$SPEC_DIR/plan-frontend.md"
  render_template "$TEMPLATE_DIR/plan-backend-template.md" "$SPEC_DIR/plan-backend.md"
else
  if [ -f "$SPEC_DIR/plan-frontend.md" ] || [ -f "$SPEC_DIR/plan-backend.md" ]; then
    log_warn "Owner 為一人（不拆檔），但分邊計劃已存在 — 請將內容併回 plan.md 後刪除 plan-frontend.md／plan-backend.md"
  fi
  render_template "$TEMPLATE_DIR/plan-template.md" "$SPEC_DIR/plan.md"
fi

# Create contracts directory
mkdir -p "$SPEC_DIR/contracts"
if [ ! -f "$SPEC_DIR/contracts/.gitkeep" ]; then
  touch "$SPEC_DIR/contracts/.gitkeep"
  log_success "Created: $SPEC_DIR/contracts/"
fi

echo ""
log_success "Plan artifacts ready for: $BRANCH_NAME"
echo "  Layout:    $MODE"
echo "  Plan:      $SPEC_DIR/plan.md"
if [ "$MODE" = split ]; then
  echo "             $SPEC_DIR/plan-frontend.md"
  echo "             $SPEC_DIR/plan-backend.md"
fi
echo "  Contracts: $SPEC_DIR/contracts/"
echo ""
echo "Next step: Complete the plan, then run /speckit-tasks"
