#!/usr/bin/env bash
set -euo pipefail

# validate-repos-yaml.sh — Lint and validate project/project-repositories.yaml
# Usage: validate-repos-yaml.sh [path/to/file.yaml]
# Exit: 0 = valid, 1 = errors

YAML_FILE="${1:-project/project-repositories.yaml}"

if [[ ! -f "$YAML_FILE" ]]; then
  echo "ERROR: File not found: $YAML_FILE" >&2
  exit 1
fi

python3 << PYEOF
import sys, yaml

with open("$YAML_FILE") as f:
    doc = yaml.safe_load(f)

errors = []

if not isinstance(doc, dict):
    errors.append("Document must be a YAML mapping")
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)

# Required top-level keys
for key in ['repositories', 'selection_guidelines']:
    if key not in doc:
        errors.append(f"Missing required top-level key: {key}")

repos = doc.get('repositories', {})
if not repos or not isinstance(repos, dict):
    errors.append("repositories must be a non-empty mapping (at least 1 entry)")
else:
    valid_gate_levels = ['minimal', 'standard', 'full']
    valid_statuses = ['proposed', 'planned', 'active', 'legacy', 'archived']
    required_fields = ['purpose', 'description', 'default_gate_level', 'status', 'when_to_use']
    required_git_fields = ['organization', 'repository', 'clone_url', 'default_branch']

    for name, entry in repos.items():
        if not isinstance(entry, dict):
            errors.append(f"{name}: entry must be a mapping")
            continue

        for field in required_fields:
            if field not in entry:
                errors.append(f"{name}: missing required field '{field}'")

        if entry.get('default_gate_level') not in valid_gate_levels:
            errors.append(f"{name}: default_gate_level must be one of {valid_gate_levels}")

        if entry.get('status') not in valid_statuses:
            errors.append(f"{name}: status must be one of {valid_statuses}")

        when_to_use = entry.get('when_to_use', [])
        if not isinstance(when_to_use, list) or len(when_to_use) == 0:
            errors.append(f"{name}: when_to_use must be a non-empty list")

        status = entry.get('status')
        gate = entry.get('default_gate_level')
        if status in ('archived', 'legacy') and gate == 'full':
            errors.append(f"{name}: status '{status}' is incompatible with default_gate_level 'full'")

        git = entry.get('git', {})
        if not isinstance(git, dict):
            errors.append(f"{name}: git must be a mapping")
        else:
            for gf in required_git_fields:
                if gf not in git:
                    errors.append(f"{name}: missing git.{gf}")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
else:
    print("VALID")
    sys.exit(0)
PYEOF
