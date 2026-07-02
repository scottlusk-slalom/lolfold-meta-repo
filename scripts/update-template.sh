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
TEMP_CLONE=""

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
# Cleanup
# ──────────────────────────────────────────────
cleanup() {
  if [[ -n "$TEMP_CLONE" && -d "$TEMP_CLONE" ]]; then
    rm -rf "$TEMP_CLONE"
  fi
}
trap cleanup EXIT

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

# Read a scalar value: yaml_scalar "key:" file
yaml_scalar() {
  local key="$1" file="$2"
  grep "^${key}" "$file" | head -1 \
    | sed 's/^[^:]*: *//' \
    | sed 's/ *#.*//' \
    | tr -d '"'"'"
}

# Read a nested scalar: yaml_nested "parent:" "  key:" file
yaml_nested() {
  local parent="$1" child="$2" file="$3"
  awk "/^${parent}/{f=1} f && /^${child}/{print; exit}" "$file" \
    | sed 's/^[^:]*: *//' \
    | sed 's/ *#.*//' \
    | tr -d '"'"'"
}

# Parse a top-level list section into an array
# Usage: read_yaml_list ARRAY_NAME "section" file
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

if ! command -v python3 &>/dev/null; then
  err "python3 is not installed (required for YAML parsing)."; prereq_ok=false
fi

if [[ ! -f "$MANIFEST" ]]; then
  err "template-manifest.yaml not found at $MANIFEST"
  err "Is this a harness-derived repo? Expected file: $MANIFEST"
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
# 3. Resolve upstream
# ──────────────────────────────────────────────
section "Resolving upstream..."

if [[ "$UPSTREAM_REPO" == http* || "$UPSTREAM_REPO" == git@* ]]; then
  TEMP_CLONE="/tmp/harness-template-sync-$$"
  info "Cloning from $UPSTREAM_REPO..."
  if ! git clone --depth 1 --quiet "$UPSTREAM_REPO" "$TEMP_CLONE" 2>&1; then
    err "Failed to clone upstream: $UPSTREAM_REPO"
    err "Check the URL and your network access, then retry."
    exit 1
  fi
  UPSTREAM_DIR="$TEMP_CLONE"
else
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
  done < <(find "$OVERRIDES_DIR" -type f -print0)

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
    # Match exact file or prefix (directory override)
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
    changed="$(rsync -an --delete "$src/" "$dst/" 2>/dev/null | grep -v '/$' | wc -l | tr -d ' ')"
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

    # Three-way merge base: prefer .template-cache/<pinned_version>/<file> (exact
    # upstream state at last sync), fall back to git HEAD, then local copy.
    base_tmp="$(mktemp /tmp/merge-base-XXXXXX)"
    CACHE_BASE="$CACHE_DIR/${LOCAL_VERSION:-unknown}/$mpath"
    if [[ -f "$CACHE_BASE" ]]; then
      cp "$CACHE_BASE" "$base_tmp"
      dim "    base: .template-cache/${LOCAL_VERSION:-unknown}/$mpath"
    elif git -C "$REPO_ROOT" show "HEAD:$mpath" > "$base_tmp" 2>/dev/null; then
      dim "    base: git HEAD:$mpath  (no cache entry for v${LOCAL_VERSION:-unknown})"
    else
      cp "$dst" "$base_tmp"
      dim "    base: local copy (no cache, no HEAD)"
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
fi

# ──────────────────────────────────────────────
# 10. Populate template cache
# ──────────────────────────────────────────────
# Store upstream merge[] files at the new version so future syncs have
# the correct three-way base (upstream-at-pin | local | upstream-now).
if [[ "$DRY_RUN" == false && -n "$UPSTREAM_VERSION" && ${#MERGE_PATHS[@]} -gt 0 ]]; then
  section "Updating .template-cache/..."
  for mpath in "${MERGE_PATHS[@]}"; do
    src="$UPSTREAM_DIR/$mpath"
    cache_dst="$CACHE_DIR/$UPSTREAM_VERSION/$mpath"
    if [[ -f "$src" ]]; then
      mkdir -p "$(dirname "$cache_dst")"
      cp "$src" "$cache_dst"
      ok "  cached  .template-cache/$UPSTREAM_VERSION/$mpath"
    fi
  done
fi

# ──────────────────────────────────────────────
# 11. Final report
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
# 12. Commit prompt
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
