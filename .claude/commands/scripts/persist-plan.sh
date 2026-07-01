#!/usr/bin/env bash
set -euo pipefail

# persist-plan.sh — Copy plan from ephemeral worktree to tracked plans/ directory
# Usage: persist-plan.sh <spec-type> <spec-key> <repo-name>

SPEC_TYPE="${1:-}"
SPEC_KEY="${2:-}"
REPO_NAME="${3:-}"

if [[ -z "$SPEC_TYPE" || -z "$SPEC_KEY" || -z "$REPO_NAME" ]]; then
  echo "Usage: persist-plan.sh <spec-type> <spec-key> <repo-name>" >&2
  exit 1
fi

SOURCE_DIR="specs/${SPEC_TYPE}/${SPEC_KEY}/repo/${REPO_NAME}/_working/${SPEC_KEY}"
DEST_DIR="specs/${SPEC_TYPE}/${SPEC_KEY}/plans"

mkdir -p "$DEST_DIR"

# Standard mode: single plan file
if [[ -f "${SOURCE_DIR}/impl-plan.md" ]]; then
  cp "${SOURCE_DIR}/impl-plan.md" "${DEST_DIR}/${REPO_NAME}.plan.md"
  echo "Persisted plan: ${DEST_DIR}/${REPO_NAME}.plan.md"
# Split mode: phases/build/plans/ directory
elif [[ -d "${SOURCE_DIR}/phases/build/plans/" ]]; then
  cp -r "${SOURCE_DIR}/phases/build/plans/"* "${DEST_DIR}/" 2>/dev/null || true
  echo "Persisted split plans to: ${DEST_DIR}/"
else
  echo "No plan found at ${SOURCE_DIR} (not an error)"
fi

exit 0
