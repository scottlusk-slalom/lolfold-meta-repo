#!/usr/bin/env bash
set -euo pipefail

# clone.sh — Clone or pull all legacy reference repos
# Usage: ./architecture/legacy/clone.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${SCRIPT_DIR}/repos"

mkdir -p "$TARGET_DIR"

# Add legacy repos here. Format: [directory]="clone-url"
# Set URL to "TODO" to skip.
declare -A REPOS=(
  # [legacy-app]="https://github.com/<YOUR_ORG>/legacy-app.git"
  # [legacy-api]="https://github.com/<YOUR_ORG>/legacy-api.git"
)

for dir in "${!REPOS[@]}"; do
  url="${REPOS[$dir]}"
  target="${TARGET_DIR}/${dir}"

  if [[ "$url" == "TODO" ]]; then
    echo "SKIP: ${dir} (URL is TODO)"
    continue
  fi

  if [[ -d "${target}/.git" ]]; then
    echo "PULL: ${dir}"
    git -C "$target" pull --quiet
  else
    echo "CLONE: ${dir}"
    git clone --depth=1 "$url" "$target"
  fi
done

echo "Done."
