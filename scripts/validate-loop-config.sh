#!/usr/bin/env bash
set -euo pipefail

# validate-loop-config.sh — Validate _loop-config.yaml against the loop config schema
# Usage: validate-loop-config.sh [path/to/_loop-config.yaml]
# Exit: 0 = valid, 1 = errors, 2 = file not found

CONFIG_FILE="${1:-_loop-config.yaml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: File not found: $CONFIG_FILE" >&2
  exit 2
fi

ERRORS=0

error() {
  echo "ERROR: $1" >&2
  ERRORS=$((ERRORS + 1))
}

# Try Node.js first, fall back to Python
if command -v node >/dev/null 2>&1; then
  node -e "
const fs = require('fs');
const yaml = require('js-yaml') || (() => { throw new Error('no js-yaml'); })();
const doc = yaml.load(fs.readFileSync('$CONFIG_FILE', 'utf8'));
process.stdout.write(JSON.stringify(doc));
" 2>/dev/null && exit 0 || true
fi

# Python fallback with pyyaml
PARSED=$(python3 -c "
import sys, yaml, json
with open('$CONFIG_FILE') as f:
    doc = yaml.safe_load(f)
print(json.dumps(doc))
" 2>/dev/null) || { echo "ERROR: Cannot parse YAML (install js-yaml or pyyaml)" >&2; exit 1; }

# Validate using Python
python3 << 'PYEOF'
import sys, json

doc = json.loads('''PARSED_PLACEHOLDER'''.replace('PARSED_PLACEHOLDER', r"""$PARSED"""))

errors = []

# Required top-level keys
for key in ['version', 'test', 'gates', 'compliance', 'topology', 'commit']:
    if key not in doc:
        errors.append(f"Missing required top-level key: {key}")

if 'version' in doc and not doc['version']:
    errors.append("version must be non-empty")

if 'test' in doc:
    t = doc['test']
    frameworks = ['jest', 'vitest', 'mocha', 'pytest', 'go-test']
    if t.get('framework') not in frameworks:
        errors.append(f"test.framework must be one of: {frameworks}")
    cov = t.get('coverage_threshold')
    if not isinstance(cov, int) or cov < 0 or cov > 100:
        errors.append("test.coverage_threshold must be integer 0-100")

if 'gates' in doc:
    g = doc['gates']
    levels = ['minimal', 'standard', 'full']
    if g.get('default_level') not in levels:
        errors.append(f"gates.default_level must be one of: {levels}")
    for k, v in g.get('overrides', {}).items():
        if v not in levels:
            errors.append(f"gates.overrides.{k} must be one of: {levels}")

if 'compliance' in doc:
    c = doc['compliance']
    rules = c.get('rules', [])
    if not rules:
        errors.append("compliance.rules must be non-empty")
    for required in ['SEC-001', 'SEC-002', 'PLAT-001']:
        if required not in rules:
            errors.append(f"compliance.rules must include {required}")

if 'topology' in doc:
    modes = ['single', 'multi-module']
    if doc['topology'].get('mode') not in modes:
        errors.append(f"topology.mode must be one of: {modes}")

if 'commit' in doc:
    formats = ['conventional', 'none']
    if doc['commit'].get('format') not in formats:
        errors.append(f"commit.format must be one of: {formats}")

if errors:
    for e in errors:
        print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
else:
    print("VALID")
    sys.exit(0)
PYEOF
