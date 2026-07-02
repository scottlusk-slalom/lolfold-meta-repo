#!/usr/bin/env bash

#==============================================================================
# contribute-upstream.sh
#==============================================================================
#
# SYNOPSIS
#     Push local framework overrides and source registrations back to the
#     upstream harness template as a pull request. Operates inside the
#     .template-cache/ clone (whose origin is the template repo).
#
# USAGE
#     ./scripts/contribute-upstream.sh [OPTIONS]
#
# FLAGS
#     --dry-run              Detect candidates and show PR preview; no remote ops
#     --scope <type>         Limit to: framework | source | all (default: all)
#     --rationale <text>     Explanation for reviewers (required for live run)
#     --fork                 Force PR via fork (instead of direct branch push)
#     -h, --help             Show this help
#
# EXAMPLES
#     ./scripts/contribute-upstream.sh --dry-run
#     ./scripts/contribute-upstream.sh --scope framework --rationale "Add retry logic to sync"
#     ./scripts/contribute-upstream.sh --fork --rationale "New ADR source"
#
#==============================================================================

set -euo pipefail

# ──────────────────────────────────────────────
# Colors
# ──────────────────────────────────────────────
readonly C_CYAN='\033[0;36m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[1;33m'
readonly C_RED='\033[0;31m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'
readonly C_RESET='\033[0m'

# ──────────────────────────────────────────────
# Logging
# ──────────────────────────────────────────────
info()    { echo -e "${C_CYAN}▸${C_RESET} $*"; }
ok()      { echo -e "${C_GREEN}✓${C_RESET} $*"; }
warn()    { echo -e "${C_YELLOW}⚠${C_RESET} $*"; }
err()     { echo -e "${C_RED}✗${C_RESET} $*" >&2; }
section() { echo -e "\n${C_BOLD}$*${C_RESET}"; }
dim()     { echo -e "${C_DIM}$*${C_RESET}"; }

# ──────────────────────────────────────────────
# Globals
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/template-manifest.yaml"
OVERRIDES_DIR="$REPO_ROOT/.template-overrides"
CACHE_DIR="$REPO_ROOT/.template-cache"
CONTRIBUTION_RECORD="$REPO_ROOT/.template-contribution.yaml"

DRY_RUN=false
SCOPE="all"
RATIONALE=""
FORCE_FORK=false

declare -a OVERRIDE_CANDIDATES=()
declare -a SOURCE_CANDIDATES=()

# ──────────────────────────────────────────────
# Parse arguments
# ──────────────────────────────────────────────
show_help() {
  sed -n '/^# SYNOPSIS/,/^#==/p' "$0" | sed 's/^# \?//' | sed '1d;$d'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --scope)      SCOPE="$2"; shift 2 ;;
    --rationale)  RATIONALE="$2"; shift 2 ;;
    --fork)       FORCE_FORK=true; shift ;;
    -h|--help)    show_help ;;
    *) err "Unknown option: $1"; echo "Use --help for usage."; exit 1 ;;
  esac
done

if [[ "$SCOPE" != "all" && "$SCOPE" != "framework" && "$SCOPE" != "source" ]]; then
  err "Invalid --scope: $SCOPE (must be: framework | source | all)"
  exit 1
fi

if [[ "$DRY_RUN" == false && -z "$RATIONALE" ]]; then
  err "--rationale is required for live runs (explains the contribution to reviewers)"
  echo ""
  echo "  Example: --rationale \"Add retry logic to template sync for flaky networks\""
  echo "  Or use --dry-run to preview without a rationale."
  exit 1
fi

# ──────────────────────────────────────────────
# YAML helpers
# ──────────────────────────────────────────────
yaml_scalar() {
  local key="$1" file="$2"
  grep "^${key}" "$file" | head -1 \
    | sed 's/^[^:]*: *//' \
    | sed 's/ *#.*//' \
    | tr -d '"'"'"
}

yaml_nested() {
  local parent="$1" child="$2" file="$3"
  awk "/^${parent}/{f=1} f && /^${child}/{print; exit}" "$file" \
    | sed 's/^[^:]*: *//' \
    | sed 's/ *#.*//' \
    | tr -d '"'"'"
}

# ──────────────────────────────────────────────
# 1. Prerequisites
# ──────────────────────────────────────────────
section "Checking prerequisites..."

prereq_ok=true

if ! command -v git &>/dev/null; then
  err "git is not installed."; prereq_ok=false
fi

if ! git -C "$REPO_ROOT" rev-parse --git-dir &>/dev/null; then
  err "Not inside a git repository: $REPO_ROOT"; prereq_ok=false
fi

if ! command -v python3 &>/dev/null; then
  err "python3 is not installed (required for YAML operations)."; prereq_ok=false
fi

if [[ ! -f "$MANIFEST" ]]; then
  err "template-manifest.yaml not found at $MANIFEST"
  prereq_ok=false
fi

[[ "$prereq_ok" == false ]] && { echo ""; err "Prerequisites not met. Aborting."; exit 1; }

ok "Prerequisites OK"

# ──────────────────────────────────────────────
# 2. Read manifest
# ──────────────────────────────────────────────
section "Reading template-manifest.yaml..."

LOCAL_VERSION="$(yaml_nested "upstream:" "  pinned_at:" "$MANIFEST")"
UPSTREAM_REPO="$(yaml_nested "upstream:" "  repo:" "$MANIFEST")"
TEMPLATE_VERSION="$(yaml_scalar "template_version:" "$MANIFEST")"

if [[ -z "$UPSTREAM_REPO" ]]; then
  err "upstream.repo is not set in template-manifest.yaml."
  echo ""
  echo "  Set upstream.repo to the template's git URL, then retry."
  exit 1
fi

# Derive instance identity from origin URL
INSTANCE_ORIGIN="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "unknown")"
INSTANCE_ID="$(basename "$INSTANCE_ORIGIN" .git)"

ok "Instance:  $INSTANCE_ID"
info "Upstream:  $UPSTREAM_REPO"
info "Pinned at: ${LOCAL_VERSION:-unknown}"

# ──────────────────────────────────────────────
# 3. Resolve .template-cache/ clone
# ──────────────────────────────────────────────
# Ensure cache is returned to default branch on exit/interrupt
cleanup_cache() {
  if [[ -d "$CACHE_DIR/.git" ]]; then
    local current_branch
    current_branch="$(git -C "$CACHE_DIR" branch --show-current 2>/dev/null || true)"
    if [[ "$current_branch" == contribute/* ]]; then
      git -C "$CACHE_DIR" checkout main --quiet 2>/dev/null \
        || git -C "$CACHE_DIR" checkout master --quiet 2>/dev/null || true
    fi
  fi
}
trap cleanup_cache EXIT

section "Resolving template cache..."

if [[ ! -d "$CACHE_DIR/.git" ]]; then
  err ".template-cache/ is not a git clone."
  echo ""
  echo "  Run /update-template first to establish the upstream cache clone."
  echo "  (update-template shallow-clones the upstream into .template-cache/)"
  exit 1
fi

# Verify remote points to upstream
CACHE_REMOTE="$(git -C "$CACHE_DIR" remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$CACHE_REMOTE" ]]; then
  err ".template-cache/ has no origin remote."
  echo "  Delete .template-cache/ and re-run /update-template to recreate it."
  exit 1
fi

ok "Cache clone: $CACHE_REMOTE"

# ──────────────────────────────────────────────
# 4. Refresh + unshallow the cache
# ──────────────────────────────────────────────
section "Refreshing cache clone..."

info "Fetching upstream..."
git -C "$CACHE_DIR" fetch origin --quiet 2>&1 || {
  err "Failed to fetch from upstream. Check network access."
  exit 1
}

# Unshallow if needed — contribute requires full history to cleanly push a branch
if git -C "$CACHE_DIR" rev-parse --is-shallow-repository 2>/dev/null | grep -q true; then
  info "Unshallowing cache clone (required for branch push)..."
  git -C "$CACHE_DIR" fetch --unshallow --quiet 2>&1 || {
    err "Failed to unshallow cache. Check network access."
    exit 1
  }
  git -C "$CACHE_DIR" fetch --tags --quiet 2>&1 || true
fi

# Reset to upstream HEAD
git -C "$CACHE_DIR" checkout "$(git -C "$CACHE_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)" --quiet 2>/dev/null \
  || git -C "$CACHE_DIR" checkout main --quiet 2>/dev/null \
  || git -C "$CACHE_DIR" checkout master --quiet
git -C "$CACHE_DIR" reset --hard origin/HEAD --quiet 2>/dev/null \
  || git -C "$CACHE_DIR" reset --hard FETCH_HEAD --quiet

ok "Cache refreshed and unshallowed"

# ──────────────────────────────────────────────
# 5. Detect framework override candidates
# ──────────────────────────────────────────────
if [[ "$SCOPE" == "all" || "$SCOPE" == "framework" ]]; then
  section "Detecting framework override candidates..."

  if [[ -d "$OVERRIDES_DIR" ]]; then
    while IFS= read -r -d '' override_file; do
      rel="${override_file#$OVERRIDES_DIR/}"
      [[ "$rel" == "README.md" && "$(dirname "$rel")" == "." ]] && continue

      # The actual source file in the instance repo
      src="$REPO_ROOT/$rel"
      # The corresponding file in the cache (upstream HEAD)
      upstream_file="$CACHE_DIR/$rel"

      if [[ ! -f "$src" ]]; then
        # Override placeholder exists but no source file — skip
        continue
      fi

      if [[ -f "$upstream_file" ]]; then
        # File exists upstream — only a candidate if it differs
        if ! diff -q "$src" "$upstream_file" &>/dev/null; then
          OVERRIDE_CANDIDATES+=("$rel")
        fi
      else
        # File doesn't exist upstream — new contribution
        OVERRIDE_CANDIDATES+=("$rel")
      fi
    done < <(find "$OVERRIDES_DIR" -type f -not -name '.DS_Store' -print0)
  fi

  if [[ ${#OVERRIDE_CANDIDATES[@]} -gt 0 ]]; then
    echo ""
    for candidate in "${OVERRIDE_CANDIDATES[@]}"; do
      if [[ -f "$CACHE_DIR/$candidate" ]]; then
        printf "  ${C_YELLOW}modified${C_RESET}  %s\n" "$candidate"
      else
        printf "  ${C_GREEN}new${C_RESET}       %s\n" "$candidate"
      fi
    done
  else
    info "No framework override candidates found."
  fi
fi

# ──────────────────────────────────────────────
# 6. Detect source registration candidates
# ──────────────────────────────────────────────
if [[ "$SCOPE" == "all" || "$SCOPE" == "source" ]]; then
  section "Detecting source registration candidates..."

  SOURCES_LOCAL="$REPO_ROOT/org/sources.local.yaml"
  SOURCES_UPSTREAM="$CACHE_DIR/org/sources.yaml"

  if [[ -f "$SOURCES_LOCAL" ]]; then
    while IFS= read -r src_name; do
      [[ -n "$src_name" ]] && SOURCE_CANDIDATES+=("$src_name")
    done < <(python3 - "$SOURCES_LOCAL" "$SOURCES_UPSTREAM" <<'PYTHON'
import sys, yaml, os

local_file = sys.argv[1]
upstream_file = sys.argv[2]

with open(local_file) as f:
    local_data = yaml.safe_load(f) or {}

upstream_names = set()
if os.path.isfile(upstream_file):
    with open(upstream_file) as f:
        upstream_data = yaml.safe_load(f) or {}
    for src in upstream_data.get("sources", []):
        if isinstance(src, dict) and "name" in src:
            upstream_names.add(src["name"])

for src in local_data.get("sources", []):
    if isinstance(src, dict) and "name" in src:
        if src["name"] not in upstream_names:
            print(src["name"])
PYTHON
    )

    if [[ ${#SOURCE_CANDIDATES[@]} -gt 0 ]]; then
      echo ""
      for src in "${SOURCE_CANDIDATES[@]}"; do
        printf "  ${C_GREEN}new${C_RESET}       source: %s\n" "$src"
      done
    else
      info "No new source registrations to contribute."
    fi
  else
    info "No org/sources.local.yaml found — source contributions N/A."
  fi
fi

# ──────────────────────────────────────────────
# 7. Candidate gate
# ──────────────────────────────────────────────
TOTAL_CANDIDATES=$(( ${#OVERRIDE_CANDIDATES[@]} + ${#SOURCE_CANDIDATES[@]} ))

echo ""
if [[ $TOTAL_CANDIDATES -eq 0 ]]; then
  ok "Nothing to contribute."
  echo ""
  echo "  To contribute framework changes: place customized files in .template-overrides/"
  echo "  To contribute sources: add entries to org/sources.local.yaml"
  exit 0
fi

section "Contribution summary: $TOTAL_CANDIDATES candidate(s)"

# ──────────────────────────────────────────────
# 8. Build provenance envelope + PR body
# ──────────────────────────────────────────────
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LAST_SYNC="${LOCAL_VERSION:-unknown}"
BRANCH_NAME="contribute/${INSTANCE_ID}/${TIMESTAMP}"

PR_TITLE="contrib(${INSTANCE_ID}): ${SCOPE} contribution"

PR_BODY="## Upstream Contribution

| Field | Value |
|-------|-------|
| **Instance** | \`${INSTANCE_ID}\` |
| **Template version** | \`${TEMPLATE_VERSION}\` |
| **Last sync** | \`${LAST_SYNC}\` |
| **Scope** | \`${SCOPE}\` |
| **Timestamp** | \`${TIMESTAMP}\` |

### Rationale

${RATIONALE:-_(dry run — no rationale provided)_}

### Candidates
"

if [[ ${#OVERRIDE_CANDIDATES[@]} -gt 0 ]]; then
  PR_BODY+="
#### Framework Overrides
"
  for c in "${OVERRIDE_CANDIDATES[@]}"; do
    PR_BODY+="- \`${c}\`
"
  done
fi

if [[ ${#SOURCE_CANDIDATES[@]} -gt 0 ]]; then
  PR_BODY+="
#### Source Registrations
"
  for s in "${SOURCE_CANDIDATES[@]}"; do
    PR_BODY+="- \`${s}\`
"
  done
fi

PR_BODY+="
---
_Generated by \`contribute-upstream.sh\` from instance \`${INSTANCE_ID}\`_"

# ──────────────────────────────────────────────
# 9. Dry-run report + exit
# ──────────────────────────────────────────────
if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo -e "${C_BOLD}╭─────────────────────────────────────────────╮${C_RESET}"
  echo -e "${C_BOLD}│  Contribute Upstream — Dry Run              │${C_RESET}"
  echo -e "${C_BOLD}╰─────────────────────────────────────────────╯${C_RESET}"
  echo ""
  printf "  %-18s %s\n" "Branch:"    "$BRANCH_NAME"
  printf "  %-18s %s\n" "PR title:"  "$PR_TITLE"
  printf "  %-18s %s\n" "Scope:"     "$SCOPE"
  printf "  %-18s %s\n" "Candidates:" "$TOTAL_CANDIDATES"
  echo ""
  echo -e "  ${C_BOLD}PR Body:${C_RESET}"
  echo "$PR_BODY" | sed 's/^/    /'
  echo ""
  warn "Dry run complete — no remote operations performed."
  echo ""
  echo "  To submit for real:"
  echo -e "    ${C_BOLD}./scripts/contribute-upstream.sh --rationale \"your rationale here\"${C_RESET}"
  exit 0
fi

# ──────────────────────────────────────────────
# 10. Verify gh auth
# ──────────────────────────────────────────────
section "Verifying GitHub CLI authentication..."

if ! command -v gh &>/dev/null; then
  err "gh (GitHub CLI) is not installed."
  echo "  Install: brew install gh"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  err "Not authenticated with GitHub CLI."
  echo "  Run: gh auth login"
  exit 1
fi

ok "GitHub CLI authenticated"

# ──────────────────────────────────────────────
# 11. Branch, apply, commit — inside .template-cache/
# ──────────────────────────────────────────────
section "Applying contributions in cache clone..."

git -C "$CACHE_DIR" checkout -b "$BRANCH_NAME" --quiet

APPLIED=0

# Apply framework overrides
if [[ ${#OVERRIDE_CANDIDATES[@]} -gt 0 ]]; then
  for candidate in "${OVERRIDE_CANDIDATES[@]}"; do
    src="$REPO_ROOT/$candidate"
    dst="$CACHE_DIR/$candidate"

    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    ok "  applied  $candidate"
    APPLIED=$((APPLIED + 1))
  done
fi

# Apply source registrations
if [[ ${#SOURCE_CANDIDATES[@]} -gt 0 && -f "$REPO_ROOT/org/sources.local.yaml" ]]; then
  UPSTREAM_SOURCES="$CACHE_DIR/org/sources.yaml"

  mkdir -p "$(dirname "$UPSTREAM_SOURCES")"
  if [[ ! -f "$UPSTREAM_SOURCES" ]]; then
    echo "sources: []" > "$UPSTREAM_SOURCES"
  fi

  python3 - "$REPO_ROOT/org/sources.local.yaml" "$UPSTREAM_SOURCES" "${SOURCE_CANDIDATES[@]}" <<'PYTHON'
import sys, yaml, os

local_file = sys.argv[1]
upstream_file = sys.argv[2]
targets = set(sys.argv[3:])

with open(local_file) as f:
    local_data = yaml.safe_load(f) or {}

with open(upstream_file) as f:
    upstream_data = yaml.safe_load(f) or {}

if "sources" not in upstream_data:
    upstream_data["sources"] = []

for src in local_data.get("sources", []):
    if isinstance(src, dict) and src.get("name") in targets:
        upstream_data["sources"].append(src)

with open(upstream_file, "w") as f:
    yaml.dump(upstream_data, f, default_flow_style=False, sort_keys=False)
PYTHON

  for src in "${SOURCE_CANDIDATES[@]}"; do
    ok "  applied  source: $src"
    APPLIED=$((APPLIED + 1))
  done
fi

if [[ $APPLIED -eq 0 ]]; then
  err "No changes were applied — nothing to commit."
  git -C "$CACHE_DIR" checkout - --quiet
  exit 1
fi

# Commit with provenance
COMMIT_MSG="contrib(${INSTANCE_ID}): ${SCOPE} contribution

Instance: ${INSTANCE_ID}
Template version: ${TEMPLATE_VERSION}
Last sync: ${LAST_SYNC}
Scope: ${SCOPE}
Timestamp: ${TIMESTAMP}

Rationale: ${RATIONALE}"

git -C "$CACHE_DIR" add -A
git -C "$CACHE_DIR" commit -m "$COMMIT_MSG" --quiet

ok "Committed $APPLIED change(s) on branch: $BRANCH_NAME"

# ──────────────────────────────────────────────
# 12. Push + open PR, with fork fallback
# ──────────────────────────────────────────────
section "Pushing and creating pull request..."

PUSH_FAILED=false
if [[ "$FORCE_FORK" == false ]]; then
  if ! git -C "$CACHE_DIR" push origin "$BRANCH_NAME" --quiet 2>/dev/null; then
    warn "Direct push failed (likely no write access) — falling back to fork"
    PUSH_FAILED=true
  fi
fi

if [[ "$FORCE_FORK" == true || "$PUSH_FAILED" == true ]]; then
  PR_URL="$(cd "$CACHE_DIR" && gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --head "$BRANCH_NAME" \
    --fork 2>&1)" || {
    err "Failed to create PR via fork."
    err "Output: $PR_URL"
    git -C "$CACHE_DIR" checkout - --quiet
    exit 1
  }
else
  PR_URL="$(cd "$CACHE_DIR" && gh pr create \
    --title "$PR_TITLE" \
    --body "$PR_BODY" \
    --head "$BRANCH_NAME" 2>&1)" || {
    err "Failed to create PR."
    err "Output: $PR_URL"
    git -C "$CACHE_DIR" checkout - --quiet
    exit 1
  }
fi

ok "Pull request created"
echo ""
echo -e "  ${C_BOLD}$PR_URL${C_RESET}"

# ──────────────────────────────────────────────
# 13. Labels (best-effort)
# ──────────────────────────────────────────────
if [[ -n "$PR_URL" ]]; then
  (cd "$CACHE_DIR" && gh pr edit "$PR_URL" --add-label "contribution" 2>/dev/null) || true

  for candidate in "${OVERRIDE_CANDIDATES[@]}"; do
    label="path:$(dirname "$candidate")"
    (cd "$CACHE_DIR" && gh pr edit "$PR_URL" --add-label "$label" 2>/dev/null) || true
  done

  for src in "${SOURCE_CANDIDATES[@]}"; do
    (cd "$CACHE_DIR" && gh pr edit "$PR_URL" --add-label "source:$src" 2>/dev/null) || true
  done
fi

# ──────────────────────────────────────────────
# 14. Record contribution
# ──────────────────────────────────────────────
section "Recording contribution..."

cat > "$CONTRIBUTION_RECORD" <<EOF
# Auto-generated by contribute-upstream.sh — tracks the last contribution
last_contribution:
  branch: "${BRANCH_NAME}"
  pr_url: "${PR_URL}"
  instance: "${INSTANCE_ID}"
  scope: "${SCOPE}"
  template_version: "${TEMPLATE_VERSION}"
  last_sync: "${LAST_SYNC}"
  timestamp: "${TIMESTAMP}"
  candidates:
EOF

for c in "${OVERRIDE_CANDIDATES[@]}"; do
  echo "    - type: framework" >> "$CONTRIBUTION_RECORD"
  echo "      path: \"$c\"" >> "$CONTRIBUTION_RECORD"
done

for s in "${SOURCE_CANDIDATES[@]}"; do
  echo "    - type: source" >> "$CONTRIBUTION_RECORD"
  echo "      name: \"$s\"" >> "$CONTRIBUTION_RECORD"
done

ok "Recorded: .template-contribution.yaml"

# Return cache to default branch
git -C "$CACHE_DIR" checkout - --quiet 2>/dev/null || true

# ──────────────────────────────────────────────
# 15. Final report
# ──────────────────────────────────────────────
echo ""
echo -e "${C_BOLD}╭─────────────────────────────────────────────╮${C_RESET}"
echo -e "${C_BOLD}│  Contribution Report                        │${C_RESET}"
echo -e "${C_BOLD}╰─────────────────────────────────────────────╯${C_RESET}"
printf "  %-22s %s\n" "Instance:"           "$INSTANCE_ID"
printf "  %-22s %s\n" "Upstream:"           "$CACHE_REMOTE"
printf "  %-22s %s\n" "Branch:"             "$BRANCH_NAME"
printf "  %-22s %s\n" "Scope:"              "$SCOPE"
printf "  %-22s %s\n" "Candidates applied:" "$APPLIED"
printf "  %-22s %s\n" "PR:"                 "$PR_URL"
echo ""
ok "Contribution submitted for review."
echo ""
echo "  Next steps:"
echo "    • Template admins will review and merge (or request changes)"
echo "    • Once merged, other instances pick up the change via /update-template"
echo "    • If you added sources, retire the entry from org/sources.local.yaml after merge"
