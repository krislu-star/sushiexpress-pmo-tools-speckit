#!/usr/bin/env bash
# create-new-feature.sh - Creates a new feature branch and spec directory
# Usage: ./create-new-feature.sh "Feature Title" [frontend|backend]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

FEATURE_TITLE="${1:-}"
MODULE="${2:-}"  # optional: frontend | backend  (cms 為唯讀模組，見憲法 Article XII)

if [ -z "$FEATURE_TITLE" ]; then
  log_error "Usage: $0 \"Feature Title\" [frontend|backend]"
  exit 1
fi

if [ "$MODULE" = "cms" ]; then
  log_error "cms 為唯讀模組（憲法 Article XII），不得建立 CMS 功能規格"
  log_error "若需求涉及 CMS，請改用 backend 或省略模組（跨模組），透過 API／設定介面實作"
  exit 1
fi

if [ -n "$MODULE" ] && [ "$MODULE" != "frontend" ] && [ "$MODULE" != "backend" ]; then
  log_error "Module must be 'frontend' or 'backend' (or omit for shared)"
  exit 1
fi

TEMPLATE_DIR=".specify/templates"
SPECS_DIR="specs"

# Get next number and create branch name
NUM=$(get_next_feature_number)
SLUG=$(slugify "$FEATURE_TITLE")
BRANCH_NAME="${NUM}-${SLUG}"
SPEC_DIR="${SPECS_DIR}/${BRANCH_NAME}"
FULL_BRANCH="${BRANCH_NAME}"

log_info "Creating feature: $FULL_BRANCH"

# Create spec directory
mkdir -p "$SPEC_DIR"

# Copy spec template with replacements
TODAY=$(date +%Y-%m-%d)
SAFE_TITLE=$(escape_sed_replacement "$FEATURE_TITLE")
SAFE_BRANCH=$(escape_sed_replacement "$BRANCH_NAME")
sed \
  -e "s/\[FEATURE_TITLE\]/$SAFE_TITLE/g" \
  -e "s/NNN-feature-name/$SAFE_BRANCH/g" \
  -e "s/\[DATE\]/$TODAY/g" \
  "$TEMPLATE_DIR/spec-template.md" > "$SPEC_DIR/spec.md"

log_success "Created: $SPEC_DIR/spec.md"

# Create git branch if git is available
if check_git; then
  if git show-ref --verify --quiet "refs/heads/$FULL_BRANCH" 2>/dev/null; then
    log_warn "Branch '$FULL_BRANCH' already exists — switching to it"
    git checkout "$FULL_BRANCH"
  else
    git checkout -b "$FULL_BRANCH"
    log_success "Created and switched to branch: $FULL_BRANCH"
  fi
fi

echo ""
log_success "Feature '$FEATURE_TITLE' initialized!"
echo "  Module:   ${MODULE:-shared}  (參考用，未自動寫入 spec.md)"
echo "  Branch:   $FULL_BRANCH"
echo "  Spec:     $SPEC_DIR/spec.md"
echo ""
echo "Next step: Edit $SPEC_DIR/spec.md, then run /speckit-plan"
