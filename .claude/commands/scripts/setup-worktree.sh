#!/usr/bin/env bash
set -euo pipefail

# setup-worktree.sh — Create a git worktree for a repo under the spec directory
# Usage: setup-worktree.sh <repo-name> <spec-type> <spec-key> <meta-branch> [integration-branch]

REPO_NAME="${1:-}"
SPEC_TYPE="${2:-}"
SPEC_KEY="${3:-}"
META_BRANCH="${4:-}"
INTEGRATION_BRANCH="${5:-}"

if [[ -z "$REPO_NAME" || -z "$SPEC_TYPE" || -z "$SPEC_KEY" || -z "$META_BRANCH" ]]; then
  echo "Usage: setup-worktree.sh <repo-name> <spec-type> <spec-key> <meta-branch> [integration-branch]" >&2
  exit 1
fi

REPO_REF="repos/${REPO_NAME}"
WORKTREE_PATH="specs/${SPEC_TYPE}/${SPEC_KEY}/repo/${REPO_NAME}"

# Validate reference clone exists
if [[ ! -d "${REPO_REF}/.git" ]]; then
  echo "ERROR: Reference clone not found at ${REPO_REF}" >&2
  exit 1
fi

# Determine branch name
if [[ "$META_BRANCH" =~ ^(feat|fix|chore)/ ]]; then
  BRANCH_NAME="$META_BRANCH"
else
  BRANCH_NAME="feat/${SPEC_KEY}"
fi

# Detect default branch
DEFAULT_BRANCH=$(git -C "$REPO_REF" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
if [[ -z "$DEFAULT_BRANCH" ]]; then
  DEFAULT_BRANCH=$(git -C "$REPO_REF" branch -r | grep -E 'origin/(main|master)' | head -1 | sed 's|.*origin/||' | tr -d ' ')
fi
if [[ -z "$DEFAULT_BRANCH" ]]; then
  echo "ERROR: Cannot detect default branch for ${REPO_NAME}" >&2
  exit 1
fi

# Base branch for worktree
BASE="${INTEGRATION_BRANCH:-$DEFAULT_BRANCH}"

# Idempotent: reuse existing worktree
if [[ -d "$WORKTREE_PATH" ]]; then
  echo "Worktree already exists at ${WORKTREE_PATH} (reusing)"
  exit 0
fi

# Create worktree
mkdir -p "$(dirname "$WORKTREE_PATH")"
git -C "$REPO_REF" worktree add "../../${WORKTREE_PATH}" -b "$BRANCH_NAME" "origin/${BASE}" 2>/dev/null || \
  git -C "$REPO_REF" worktree add "../../${WORKTREE_PATH}" "$BRANCH_NAME" 2>/dev/null

echo "Worktree created: ${WORKTREE_PATH} on branch ${BRANCH_NAME} (base: ${BASE})"
exit 0
