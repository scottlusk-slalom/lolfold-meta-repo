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
REGISTRY="project/project-repositories.yaml"

# Read a nested git.<field> value for $REPO_NAME from the repo registry.
# Indentation-aware (not a full YAML parser): anchors on the exact top-level
# repo key (literal string compare — repo names may contain regex metachars
# like '.', so NEVER treat REPO_NAME as a regex), stops at the next 2-space
# repo key, and returns the field's value with the "key:" prefix stripped.
lookup_repo_field() {
  awk -v repo="$REPO_NAME" -v field="$1" '
    { line=$0; sub(/[ \t]+$/, "", line) }              # tolerate trailing ws
    line == "  " repo ":" { in_repo=1; next }
    in_repo && /^  [^[:space:]]/ { in_repo=0 }          # next repo key resets
    in_repo && $1 == field":" { sub(/^[^:]*:[ \t]*/, ""); print; exit }
  ' "$REGISTRY"
}

# Validate reference clone exists. In cloud dispatched-sub-agent mode the
# metarepo is a fresh clone with an EMPTY repos/ (it's gitignored — local-only,
# never committed), so the reference clone must be bootstrapped on demand from
# the registry's clone_url. Locally, a missing clone is still a hard error:
# repos/ is expected to be pre-seeded and silent cloning would mask setup drift.
if [[ ! -d "${REPO_REF}/.git" ]]; then
  IS_CLOUD_SUBAGENT="${DISPATCHED_BY_ORCHESTRATOR:-}${SUBAGENT_RUNTIME_ARN:-}"
  if [[ -z "$IS_CLOUD_SUBAGENT" ]]; then
    echo "ERROR: Reference clone not found at ${REPO_REF}" >&2
    exit 1
  fi

  if [[ ! -f "$REGISTRY" ]]; then
    echo "ERROR: ${REPO_REF} missing and registry ${REGISTRY} not found — cannot bootstrap" >&2
    exit 1
  fi

  CLONE_URL="$(lookup_repo_field clone_url)"
  if [[ -z "$CLONE_URL" ]]; then
    echo "ERROR: no git.clone_url for '${REPO_NAME}' in ${REGISTRY} — cannot bootstrap" >&2
    exit 1
  fi

  # A prior clone killed mid-flight (OOM / container reap) leaves a non-empty
  # repos/<repo>/ WITHOUT .git. git clone refuses a non-empty target, which
  # would wedge every retry permanently. Clear the partial before cloning.
  if [[ -d "$REPO_REF" ]]; then
    echo "Removing partial/stale ${REPO_REF} (no .git) before clone"
    rm -rf "$REPO_REF"
  fi

  echo "Reference clone missing (cloud sub-agent) — cloning ${REPO_NAME} from ${CLONE_URL}"
  mkdir -p repos
  if ! git clone "$CLONE_URL" "$REPO_REF"; then
    echo "ERROR: failed to clone ${REPO_NAME} from ${CLONE_URL}" >&2
    exit 1
  fi
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
  # `{ grep || true; }` so a no-match (repo has neither main nor master) does
  # not trip pipefail and kill the script before the clear error below.
  DEFAULT_BRANCH=$(git -C "$REPO_REF" branch -r | { grep -E 'origin/(main|master)' || true; } | head -1 | sed 's|.*origin/||' | tr -d ' ')
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
