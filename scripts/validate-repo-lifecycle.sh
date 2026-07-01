#!/usr/bin/env bash
set -euo pipefail

# validate-repo-lifecycle.sh — Validate lifecycle state integrity
# Usage: validate-repo-lifecycle.sh [path/to/file.yaml] [--check-urls] [--no-color]
# Exit: 0 = pass, 1 = errors, 2 = fatal

YAML_FILE="${1:-project/project-repositories.yaml}"
CHECK_URLS=false
NO_COLOR=false

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-urls) CHECK_URLS=true; shift ;;
    --no-color) NO_COLOR=true; shift ;;
    *) shift ;;
  esac
done

if [[ ! -f "$YAML_FILE" ]]; then
  echo "FATAL: File not found: $YAML_FILE" >&2
  exit 2
fi

python3 << PYEOF
import sys, yaml, re, os, subprocess

with open("$YAML_FILE") as f:
    doc = yaml.safe_load(f)

errors = []
warnings = []
check_urls = "$CHECK_URLS" == "true"

repos = doc.get('repositories', {})
if not isinstance(repos, dict):
    print("FATAL: repositories is not a mapping", file=sys.stderr)
    sys.exit(2)

seen_keys = set()
name_pattern = re.compile(r'^[a-z][a-z0-9]*(-[a-z0-9]+)*$')

for name, entry in repos.items():
    if not isinstance(entry, dict):
        continue

    # Naming convention check
    if not name_pattern.match(name):
        errors.append(f"{name}: key must match ^[a-z][a-z0-9]*(-[a-z0-9]+)*$")
    if len(name) > 25:
        errors.append(f"{name}: key exceeds 25 characters ({len(name)})")

    # Duplicate keys
    if name in seen_keys:
        errors.append(f"{name}: duplicate key")
    seen_keys.add(name)

    # Active repos: clone_url check
    status = entry.get('status', '')
    git = entry.get('git', {})
    clone_url = git.get('clone_url', '')

    if status == 'active':
        if not clone_url or clone_url == 'TBD' or '<' in clone_url or '>' in clone_url:
            errors.append(f"{name}: active repo must have valid clone_url (not empty/TBD/placeholder)")

        if check_urls and clone_url and clone_url != 'TBD':
            result = subprocess.run(['git', 'ls-remote', clone_url], capture_output=True, timeout=10)
            if result.returncode != 0:
                errors.append(f"{name}: clone_url unreachable: {clone_url}")

    # Orphan warning: active with no spec references
    if status == 'active':
        has_ref = False
        for root, dirs, files in os.walk('specs'):
            for f in files:
                if f.endswith('.spec.md'):
                    path = os.path.join(root, f)
                    try:
                        with open(path) as sf:
                            if name in sf.read():
                                has_ref = True
                                break
                    except:
                        pass
            if has_ref:
                break
        if not has_ref:
            warnings.append(f"{name}: active repo with no specs/**/*.spec.md reference (orphan?)")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
if warnings:
    for w in warnings:
        print(f"WARNING: {w}", file=sys.stderr)

sys.exit(1 if errors else 0)
PYEOF
