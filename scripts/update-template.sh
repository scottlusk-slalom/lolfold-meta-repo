#!/usr/bin/env bash

#==============================================================================
# update-template.sh
#==============================================================================
#
# SYNOPSIS
#     Sync the latest framework files from the upstream harness template into
#     this derived meta-repo. Governed by template-manifest.yaml.
#
# USAGE
#     ./scripts/update-template.sh [--check-only] [--dry-run]
#
# FLAGS
#     --check-only    Diff versions and framework paths; no writes
#     --dry-run       Simulate full sync; no writes, no manifest update
#     -h, --help      Show this help
#
# EXAMPLES
#     ./scripts/update-template.sh --check-only
#     ./scripts/update-template.sh --dry-run
#     ./scripts/update-template.sh
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

CHECK_ONLY=false
DRY_RUN=false
MODE="live"

# Report counters
FRAMEWORK_CHANGED=0
FRAMEWORK_ADDED=0
FRAMEWORK_REMOVED=0
OVERRIDE_SKIPPED=0
MERGE_CLEAN=0
MERGE_CONFLICT=0
CONFLICT_FILES=()

# ──────────────────────────────────────────────
# Parse arguments
# ──────────────────────────────────────────────
show_help() {
  sed -n '/^# SYNOPSIS/,/^#==/p' "$0" | sed 's/^# \?//' | sed '1d;$d'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=true; MODE="check-only"; shift ;;
    --dry-run)    DRY_RUN=true;    MODE="dry-run";    shift ;;
    -h|--help)    show_help ;;
    *) err "Unknown option: $1"; echo "Use --help for usage."; exit 1 ;;
  esac
done

# ──────────────────────────────────────────────
# YAML helpers (no yq dependency)
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

yaml_list() {
  local section="$1" file="$2"
  awk "
    /^${section}:/{found=1; next}
    found && /^  - /{
      line=\$0
      sub(/^  - /, \"\", line)
      gsub(/[\"']/, \"\", line)
      print line
    }
    found && /^[^ ]/{exit}
  " "$file"
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

if ! command -v rsync &>/dev/null; then
  err "rsync is not installed. Install with: brew install rsync"; prereq_ok=false
fi

if [[ ! -f "$MANIFEST" ]]; then
  err "template-manifest.yaml not found at $MANIFEST"
  err "Is this a harness-derived repo? Expected file: $MANIFEST"
  prereq_ok=false
fi

[[ "$prereq_ok" == false ]] && { echo ""; err "Prerequisites not met. Aborting."; exit 1; }

ok "Prerequisites OK"

if [[ "$CHECK_ONLY" == false && "$DRY_RUN" == false ]]; then
  if [[ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]]; then
    err "Working tree has uncommitted changes."
    echo "  Commit or stash before syncing to avoid losing work."
    exit 1
  fi
fi

# ──────────────────────────────────────────────
# 2. Read manifest
# ──────────────────────────────────────────────
section "Reading template-manifest.yaml..."

LOCAL_VERSION="$(yaml_nested "upstream:" "  pinned_at:" "$MANIFEST")"
UPSTREAM_REPO="$(yaml_nested "upstream:" "  repo:" "$MANIFEST")"

FRAMEWORK_PATHS=()
while IFS= read -r _line; do FRAMEWORK_PATHS+=("$_line"); done < <(yaml_list "framework" "$MANIFEST")
MERGE_PATHS=()
while IFS= read -r _line; do MERGE_PATHS+=("$_line"); done < <(yaml_list "merge" "$MANIFEST")

if [[ -z "$UPSTREAM_REPO" ]]; then
  echo ""
  err "upstream.repo is not set in template-manifest.yaml."
  echo ""
  echo "  Open template-manifest.yaml and set:"
  echo "    upstream:"
  echo "      repo: /path/to/ae-harness-platform-poc   # local clone path OR git URL"
  echo ""
  echo "  Then retry: ./scripts/update-template.sh"
  exit 1
fi

ok "Local pinned version: ${LOCAL_VERSION:-unknown}"
info "Upstream:             $UPSTREAM_REPO"
info "Framework paths:      ${#FRAMEWORK_PATHS[@]}"
info "Merge paths:          ${#MERGE_PATHS[@]}"

# ──────────────────────────────────────────────
# 3. Resolve upstream into .template-cache/
# ──────────────────────────────────────────────
section "Resolving upstream..."

if [[ "$UPSTREAM_REPO" == http* || "$UPSTREAM_REPO" == git@* ]]; then
  # Remote URL — use .template-cache/ as a persistent shallow clone
  if [[ -d "$CACHE_DIR/.git" ]]; then
    # Cache clone exists — fetch latest
    info "Fetching latest from upstream..."
    git -C "$CACHE_DIR" fetch origin --depth 1 --quiet 2>&1 || {
      err "Failed to fetch upstream. Check network access."
      exit 1
    }
    git -C "$CACHE_DIR" reset --hard origin/HEAD --quiet 2>/dev/null \
      || git -C "$CACHE_DIR" reset --hard FETCH_HEAD --quiet
  else
    # First sync — create the shallow clone
    info "Creating template cache (shallow clone)..."
    rm -rf "$CACHE_DIR"
    if ! git clone --depth 1 --quiet "$UPSTREAM_REPO" "$CACHE_DIR" 2>&1; then
      err "Failed to clone upstream: $UPSTREAM_REPO"
      err "Check the URL and your network access, then retry."
      exit 1
    fi
  fi
  UPSTREAM_DIR="$CACHE_DIR"
else
  # Local path — use directly (no cache needed for local)
  UPSTREAM_DIR="$UPSTREAM_REPO"
  if [[ ! -d "$UPSTREAM_DIR" ]]; then
    err "Upstream path not found: $UPSTREAM_DIR"
    err "Update upstream.repo in template-manifest.yaml with a valid local path or git URL."
    exit 1
  fi
fi

UPSTREAM_MANIFEST="$UPSTREAM_DIR/template-manifest.yaml"
if [[ ! -f "$UPSTREAM_MANIFEST" ]]; then
  err "No template-manifest.yaml found in upstream: $UPSTREAM_DIR"
  err "This does not appear to be an ae-harness-platform-poc source repo."
  exit 1
fi

ok "Upstream resolved: $UPSTREAM_DIR"

# ──────────────────────────────────────────────
# 4. Version check
# ──────────────────────────────────────────────
section "Checking versions..."

UPSTREAM_VERSION="$(yaml_scalar "template_version:" "$UPSTREAM_MANIFEST")"

echo ""
echo -e "  Local pinned:  ${C_BOLD}${LOCAL_VERSION:-unknown}${C_RESET}"
echo -e "  Upstream:      ${C_BOLD}${UPSTREAM_VERSION:-unknown}${C_RESET}"
echo ""

if [[ "$LOCAL_VERSION" == "$UPSTREAM_VERSION" && "$CHECK_ONLY" == false ]]; then
  ok "Already up to date (v${LOCAL_VERSION})"
  exit 0
fi

if [[ "$LOCAL_VERSION" == "$UPSTREAM_VERSION" ]]; then
  ok "Already up to date (v${LOCAL_VERSION})"
fi

# ──────────────────────────────────────────────
# 5. Build override skip list
# ──────────────────────────────────────────────
OVERRIDE_PATHS=()
if [[ -d "$OVERRIDES_DIR" ]]; then
  while IFS= read -r -d '' override_file; do
    rel="${override_file#$OVERRIDES_DIR/}"
    OVERRIDE_PATHS+=("$rel")
  done < <(find "$OVERRIDES_DIR" -type f -not -name '.DS_Store' -not -name 'README.md' -print0)

  if [[ ${#OVERRIDE_PATHS[@]} -gt 0 ]]; then
    section "Active overrides (.template-overrides/):"
    for op in "${OVERRIDE_PATHS[@]}"; do
      echo "  override  $op"
    done
  fi
fi

is_overridden() {
  local target="$1"
  for op in "${OVERRIDE_PATHS[@]}"; do
    if [[ "$target" == "$op" || "$target" == "$op"/* ]]; then
      return 0
    fi
  done
  return 1
}

# ──────────────────────────────────────────────
# 6. Diff report
# ──────────────────────────────────────────────
section "Framework diff (v${LOCAL_VERSION:-?} → v${UPSTREAM_VERSION:-?}):"
echo ""

for fpath in "${FRAMEWORK_PATHS[@]}"; do
  src="$UPSTREAM_DIR/$fpath"
  dst="$REPO_ROOT/$fpath"

  if is_overridden "$fpath"; then
    printf "  %-8s %s  %s\n" "OVERRIDE" "$fpath" "${C_DIM}(skipped — .template-overrides/$fpath)${C_RESET}"
    OVERRIDE_SKIPPED=$((OVERRIDE_SKIPPED + 1))
    continue
  fi

  if [[ ! -e "$src" ]]; then
    printf "  %-8s %s\n" "REMOVED" "$fpath"
    FRAMEWORK_REMOVED=$((FRAMEWORK_REMOVED + 1))
    continue
  fi

  if [[ ! -e "$dst" ]]; then
    printf "  ${C_GREEN}%-8s${C_RESET} %s\n" "ADDED" "$fpath"
    FRAMEWORK_ADDED=$((FRAMEWORK_ADDED + 1))
    continue
  fi

  if [[ -d "$src" ]]; then
    changed="$(rsync -an --delete "$src/" "$dst/" 2>/dev/null | { grep -v '/$' || true; } | wc -l | tr -d ' ')"
    if [[ "$changed" -gt 0 ]]; then
      printf "  ${C_YELLOW}%-8s${C_RESET} %s  %s\n" "CHANGED" "$fpath" "${C_DIM}($changed file(s))${C_RESET}"
      FRAMEWORK_CHANGED=$((FRAMEWORK_CHANGED + changed))
    else
      printf "  %-8s %s\n" "same" "$fpath"
    fi
  else
    if ! diff -q "$dst" "$src" &>/dev/null; then
      printf "  ${C_YELLOW}%-8s${C_RESET} %s\n" "CHANGED" "$fpath"
      FRAMEWORK_CHANGED=$((FRAMEWORK_CHANGED + 1))
    else
      printf "  %-8s %s\n" "same" "$fpath"
    fi
  fi
done

echo ""

# ──────────────────────────────────────────────
# Exit here for --check-only
# ──────────────────────────────────────────────
if [[ "$CHECK_ONLY" == true ]]; then
  echo -e "${C_BOLD}╭─────────────────────────────────────────────╮${C_RESET}"
  echo -e "${C_BOLD}│  Template Sync Report                       │${C_RESET}"
  echo -e "${C_BOLD}╰─────────────────────────────────────────────╯${C_RESET}"
  printf "  %-22s %s\n"  "Mode:"              "$MODE"
  printf "  %-22s %s\n"  "From version:"      "v${LOCAL_VERSION:-unknown}"
  printf "  %-22s %s\n"  "To version:"        "v${UPSTREAM_VERSION:-unknown}"
  printf "  %-22s %s\n"  "Upstream:"          "$UPSTREAM_REPO"
  echo ""
  printf "  %-22s %s\n"  "Framework changed:" "$FRAMEWORK_CHANGED"
  printf "  %-22s %s\n"  "Framework added:"   "$FRAMEWORK_ADDED"
  printf "  %-22s %s\n"  "Framework removed:" "$FRAMEWORK_REMOVED"
  printf "  %-22s %s\n"  "Overrides skipped:" "$OVERRIDE_SKIPPED"
  echo ""
  echo -e "  Status: $(ok "Check complete (no changes made)")"
  exit 0
fi

# ──────────────────────────────────────────────
# 7. Sync framework paths (skip in --dry-run)
# ──────────────────────────────────────────────
section "Syncing framework paths..."

if [[ "$DRY_RUN" == true ]]; then
  warn "DRY RUN — no files will be written"
  echo ""
fi

for fpath in "${FRAMEWORK_PATHS[@]}"; do
  src="$UPSTREAM_DIR/$fpath"
  dst="$REPO_ROOT/$fpath"

  if is_overridden "$fpath"; then
    dim "  skip (override)  $fpath"
    continue
  fi

  if [[ ! -e "$src" ]]; then
    dim "  skip (not in upstream)  $fpath"
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    info "  would sync  $fpath"
    continue
  fi

  if [[ -d "$src" ]]; then
    mkdir -p "$dst"
    rsync -a --delete "$src/" "$dst/"
    ok "  synced (dir)   $fpath"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    ok "  synced (file)  $fpath"
  fi
done

# ──────────────────────────────────────────────
# 8. Merge review
# ──────────────────────────────────────────────
if [[ ${#MERGE_PATHS[@]} -gt 0 ]]; then
  section "Merging paths..."

  for mpath in "${MERGE_PATHS[@]}"; do
    src="$UPSTREAM_DIR/$mpath"
    dst="$REPO_ROOT/$mpath"

    if [[ ! -f "$src" || ! -f "$dst" ]]; then
      dim "  skip  $mpath  (not present in both)"
      continue
    fi

    if diff -q "$dst" "$src" &>/dev/null; then
      ok "  same  $mpath"
      MERGE_CLEAN=$((MERGE_CLEAN + 1))
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      warn "  would merge  $mpath"
      continue
    fi

    # Three-way merge base: use the cache clone at the pinned version.
    # If upstream is a git URL, the cache IS the clone — check if we can
    # retrieve the file at the pinned commit. Otherwise fall back to git HEAD.
    base_tmp="$(mktemp /tmp/merge-base-XXXXXX)"
    BASE_FOUND=false

    if [[ -d "$CACHE_DIR/.git" && -n "$LOCAL_VERSION" ]]; then
      # Try to get the file at the pinned version tag/ref
      if git -C "$CACHE_DIR" show "v${LOCAL_VERSION}:${mpath}" > "$base_tmp" 2>/dev/null \
         || git -C "$CACHE_DIR" show "${LOCAL_VERSION}:${mpath}" > "$base_tmp" 2>/dev/null; then
        BASE_FOUND=true
        dim "    base: cache @ v${LOCAL_VERSION}:${mpath}"
      fi
    fi

    if [[ "$BASE_FOUND" == false ]]; then
      if git -C "$REPO_ROOT" show "HEAD:$mpath" > "$base_tmp" 2>/dev/null; then
        dim "    base: git HEAD:$mpath (no cache ref for v${LOCAL_VERSION:-unknown})"
      else
        cp "$dst" "$base_tmp"
        dim "    base: local copy (no cache, no HEAD)"
      fi
    fi

    if git merge-file -q "$dst" "$base_tmp" "$src" 2>/dev/null; then
      ok "  ✓ merged cleanly  $mpath"
      MERGE_CLEAN=$((MERGE_CLEAN + 1))
    else
      warn "  ✗ conflicts       $mpath"
      MERGE_CONFLICT=$((MERGE_CONFLICT + 1))
      CONFLICT_FILES+=("$mpath")
    fi

    rm -f "$base_tmp"
  done
fi

# ──────────────────────────────────────────────
# 9. Update manifest
# ──────────────────────────────────────────────
if [[ "$DRY_RUN" == false && -n "$UPSTREAM_VERSION" ]]; then
  if grep -q 'pinned_at:' "$MANIFEST"; then
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i "s/  pinned_at:.*/  pinned_at: \"$UPSTREAM_VERSION\"/" "$MANIFEST"
    else
      sed -i '' "s/  pinned_at:.*/  pinned_at: \"$UPSTREAM_VERSION\"/" "$MANIFEST"
    fi
  fi
  ok "Manifest updated: pinned_at → v$UPSTREAM_VERSION"

  # Tag the cache clone at this version for future merge-base lookups
  if [[ -d "$CACHE_DIR/.git" ]]; then
    git -C "$CACHE_DIR" tag -f "v${UPSTREAM_VERSION}" HEAD --quiet 2>/dev/null || true
  fi
fi

# ──────────────────────────────────────────────
# 10. Final report
# ──────────────────────────────────────────────
echo ""
echo -e "${C_BOLD}╭─────────────────────────────────────────────╮${C_RESET}"
echo -e "${C_BOLD}│  Template Sync Report                       │${C_RESET}"
echo -e "${C_BOLD}╰─────────────────────────────────────────────╯${C_RESET}"
printf "  %-22s %s\n"  "Mode:"              "$MODE"
printf "  %-22s %s\n"  "From version:"      "v${LOCAL_VERSION:-unknown}"
printf "  %-22s %s\n"  "To version:"        "v${UPSTREAM_VERSION:-unknown}"
printf "  %-22s %s\n"  "Upstream:"          "$UPSTREAM_REPO"
echo ""
printf "  %-22s %s changed, %s added, %s removed\n" \
  "Framework files:" "$FRAMEWORK_CHANGED" "$FRAMEWORK_ADDED" "$FRAMEWORK_REMOVED"
printf "  %-22s %s\n"  "Overrides skipped:" "$OVERRIDE_SKIPPED"
if [[ ${#MERGE_PATHS[@]} -gt 0 ]]; then
  printf "  %-22s %s clean, %s conflicted\n" "Merge files:" "$MERGE_CLEAN" "$MERGE_CONFLICT"
fi
echo ""

# ──────────────────────────────────────────────
# 11. Commit prompt
# ──────────────────────────────────────────────
COMMIT_MSG="chore: sync harness template v${LOCAL_VERSION:-?} → v${UPSTREAM_VERSION:-?}"

if [[ "$DRY_RUN" == true ]]; then
  printf "  Status: "
  warn "Dry run complete — no files were written"
  echo ""
  echo -e "  To apply:  ${C_BOLD}./scripts/update-template.sh${C_RESET}"
  exit 0
fi

if [[ ${#CONFLICT_FILES[@]} -gt 0 ]]; then
  printf "  Status: "
  warn "Merge conflicts found — review before committing"
  echo ""
  echo "  Conflicted files:"
  for cf in "${CONFLICT_FILES[@]}"; do
    echo "    • $cf"
  done
  echo ""
  echo "  Resolve conflicts, then commit manually:"
  echo -e "    ${C_BOLD}git add -A && git commit -m \"$COMMIT_MSG\"${C_RESET}"
  exit 0
fi

printf "  Status: "
ok "Sync complete"
echo ""

# Prompt to commit
read -rp "$(echo -e "${C_CYAN}?${C_RESET} Commit these changes now? [y/N] ")" COMMIT_NOW

if [[ "$(echo "$COMMIT_NOW" | tr '[:upper:]' '[:lower:]')" == "y" ]]; then
  git -C "$REPO_ROOT" add -A
  git -C "$REPO_ROOT" commit -m "$COMMIT_MSG"
  echo ""
  ok "Committed: $COMMIT_MSG"
else
  echo ""
  echo "  Review changes:  git diff HEAD"
  echo -e "  Commit when ready: ${C_BOLD}git add -A && git commit -m \"$COMMIT_MSG\"${C_RESET}"
fi
