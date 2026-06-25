#!/usr/bin/env bash
set -euo pipefail

# sync-gp.sh — Sync Golden Path docs from platform handbook, surface diffs for review
# Usage: sync-gp.sh [--check-only] [--no-color]
#
# Configure per engagement:
HANDBOOK_REPO=""  # e.g., <YOUR_ORG>/platform-handbook
GP_SRC_PATH=""    # e.g., docs/services/golden-path/
DISTILLED_FILE="org/golden-path/requirements.md"

CHECK_ONLY=false
NO_COLOR=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=true; shift ;;
    --no-color) NO_COLOR=true; shift ;;
    *) shift ;;
  esac
done

CACHE_FILE="org/cache.yaml"

if [[ ! -f "$CACHE_FILE" ]]; then
  echo "ERROR: Cache config not found at $CACHE_FILE" >&2
  exit 1
fi

# Read stale_after_days from cache.yaml
STALE_DAYS=$(python3 -c "
import yaml
with open('$CACHE_FILE') as f:
    doc = yaml.safe_load(f)
print(doc.get('stale_after_days', 30))
" 2>/dev/null || echo "30")

# Check staleness
LAST_SYNC=$(python3 -c "
import yaml
with open('$CACHE_FILE') as f:
    doc = yaml.safe_load(f)
print(doc.get('last_sync', ''))
" 2>/dev/null || echo "")

if [[ -n "$LAST_SYNC" ]]; then
  LAST_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_SYNC" "+%s" 2>/dev/null || date -d "$LAST_SYNC" "+%s" 2>/dev/null || echo "0")
  NOW_EPOCH=$(date "+%s")
  DAYS_AGO=$(( (NOW_EPOCH - LAST_EPOCH) / 86400 ))

  if [[ "$CHECK_ONLY" == "true" ]]; then
    if [[ $DAYS_AGO -gt $STALE_DAYS ]]; then
      echo "STALE: Golden Path cache is ${DAYS_AGO} days old (threshold: ${STALE_DAYS})"
      exit 1
    else
      echo "CURRENT: Golden Path cache is ${DAYS_AGO} days old (threshold: ${STALE_DAYS})"
      exit 0
    fi
  fi
else
  if [[ "$CHECK_ONLY" == "true" ]]; then
    echo "STALE: No last_sync recorded in $CACHE_FILE"
    exit 1
  fi
fi

# Full sync
if [[ -z "$HANDBOOK_REPO" ]]; then
  echo "ERROR: HANDBOOK_REPO not configured in this script. Set per engagement." >&2
  exit 1
fi

CLONE_DIR="org/sources/platform-handbook"

echo "Syncing from ${HANDBOOK_REPO}..."
if [[ -d "${CLONE_DIR}/.git" ]]; then
  git -C "$CLONE_DIR" pull --quiet
else
  git clone --depth=1 "https://github.com/${HANDBOOK_REPO}.git" "$CLONE_DIR"
fi

# Diff and surface new lines
if [[ -n "$GP_SRC_PATH" && -f "$DISTILLED_FILE" ]]; then
  echo ""
  echo "=== New lines in handbook not yet in requirements.md ==="
  grep -h "^#\|^-\|^\*" "${CLONE_DIR}/${GP_SRC_PATH}"*.md 2>/dev/null | \
    while IFS= read -r line; do
      if ! grep -qF "$line" "$DISTILLED_FILE" 2>/dev/null; then
        echo "+ $line"
      fi
    done
  echo ""
  echo "Review above and manually update: $DISTILLED_FILE"
fi

# Update last_sync in cache.yaml
TODAY=$(date "+%Y-%m-%d")
python3 -c "
import yaml
with open('$CACHE_FILE') as f:
    doc = yaml.safe_load(f)
doc['last_sync'] = '$TODAY'
with open('$CACHE_FILE', 'w') as f:
    yaml.dump(doc, f, default_flow_style=False, sort_keys=False)
"
echo "Updated last_sync in $CACHE_FILE to $TODAY"
