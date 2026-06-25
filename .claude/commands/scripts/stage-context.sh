#!/usr/bin/env bash
set -euo pipefail

# stage-context.sh — Stage spec context into the worktree's _working/ directory
# Usage: stage-context.sh <spec-type> <spec-key> <repo-name>

SPEC_TYPE="${1:-}"
SPEC_KEY="${2:-}"
REPO_NAME="${3:-}"

if [[ -z "$SPEC_TYPE" || -z "$SPEC_KEY" || -z "$REPO_NAME" ]]; then
  echo "Usage: stage-context.sh <spec-type> <spec-key> <repo-name>" >&2
  exit 1
fi

SPEC_DIR="specs/${SPEC_TYPE}/${SPEC_KEY}"
WORKTREE="specs/${SPEC_TYPE}/${SPEC_KEY}/repo/${REPO_NAME}"
WORKING_DIR="${WORKTREE}/_working/${SPEC_KEY}"

mkdir -p "$WORKING_DIR"

# 1. Sub-spec (if exists) or main spec → spec.md
if [[ -f "${SPEC_DIR}/sub-specs/${REPO_NAME}.spec.md" ]]; then
  cp "${SPEC_DIR}/sub-specs/${REPO_NAME}.spec.md" "${WORKING_DIR}/spec.md"
elif [[ -f "${SPEC_DIR}/${SPEC_KEY}.spec.md" ]]; then
  cp "${SPEC_DIR}/${SPEC_KEY}.spec.md" "${WORKING_DIR}/spec.md"
fi

# 2. First *-analysis.md → codebase-analysis.md
ANALYSIS=$(find "${SPEC_DIR}/context/" -name '*-analysis.md' -type f 2>/dev/null | head -1)
if [[ -n "$ANALYSIS" ]]; then
  cp "$ANALYSIS" "${WORKING_DIR}/codebase-analysis.md"
fi

# 3. decisions.md
if [[ -f "${SPEC_DIR}/context/decisions.md" ]]; then
  cp "${SPEC_DIR}/context/decisions.md" "${WORKING_DIR}/decisions.md"
fi

# 4. Full context/ directory
if [[ -d "${SPEC_DIR}/context/" ]]; then
  cp -r "${SPEC_DIR}/context/" "${WORKING_DIR}/context/" 2>/dev/null || true
fi

# 5. Planning context (if planning_spec: key exists in spec frontmatter)
if grep -q "planning_spec:" "${SPEC_DIR}/${SPEC_KEY}.spec.md" 2>/dev/null; then
  PLANNING_ID=$(grep "planning_spec:" "${SPEC_DIR}/${SPEC_KEY}.spec.md" | head -1 | awk '{print $2}')
  if [[ -n "$PLANNING_ID" && -d "specs/planning/${PLANNING_ID}/context/" ]]; then
    mkdir -p "${WORKING_DIR}/planning-context/"
    cp -r "specs/planning/${PLANNING_ID}/context/"* "${WORKING_DIR}/planning-context/" 2>/dev/null || true
  fi
fi

echo "Context staged to: ${WORKING_DIR}"
exit 0
