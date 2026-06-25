#!/usr/bin/env bash
set -euo pipefail

# validate-gp.sh — Validate a repo against Golden Path rules in org/golden-path/gp-rules.json
# Usage: validate-gp.sh <local-path-or-git-url> [--rules <path>] [--category <cat>] [--no-color]

TARGET="${1:-}"
RULES_FILE="org/golden-path/gp-rules.json"
CATEGORY=""
NO_COLOR=false
TEMP_CLONE=""

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rules) RULES_FILE="$2"; shift 2 ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --no-color) NO_COLOR=true; shift ;;
    *) shift ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "Usage: validate-gp.sh <local-path-or-git-url> [--rules <path>] [--category <cat>] [--no-color]" >&2
  exit 2
fi

if [[ ! -f "$RULES_FILE" ]]; then
  echo "FATAL: Rules file not found: $RULES_FILE" >&2
  exit 2
fi

# Clone if URL
if [[ "$TARGET" == http* || "$TARGET" == git@* ]]; then
  TEMP_CLONE=$(mktemp -d)
  git clone --depth=1 "$TARGET" "$TEMP_CLONE" 2>/dev/null || { echo "FATAL: Cannot clone $TARGET" >&2; exit 2; }
  TARGET="$TEMP_CLONE"
fi

cleanup() { [[ -n "$TEMP_CLONE" ]] && rm -rf "$TEMP_CLONE"; }
trap cleanup EXIT

# Color helpers
pass() { [[ "$NO_COLOR" == "true" ]] && echo "  ✓ $1" || echo "  ✓ $1"; }
fail() { [[ "$NO_COLOR" == "true" ]] && echo "  ✗ $1" || echo "  ✗ $1"; }
skip() { [[ "$NO_COLOR" == "true" ]] && echo "  – $1" || echo "  – $1"; }

FAILURES=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse and execute rules
python3 << PYEOF
import json, sys, os, subprocess, re

with open("$RULES_FILE") as f:
    data = json.load(f)

target = "$TARGET"
category_filter = "$CATEGORY"
failures = 0

rules_by_cat = {}
for rule in data.get("rules", []):
    cat = rule.get("category", "other")
    if category_filter and cat != category_filter:
        continue
    rules_by_cat.setdefault(cat, []).append(rule)

for cat, rules in sorted(rules_by_cat.items()):
    print(f"\n[{cat}]")
    for rule in rules:
        rid = rule["id"]
        name = rule["name"]
        check = rule.get("check", {})
        ctype = check.get("type", "")

        if ctype == "file_exists":
            path = os.path.join(target, check.get("path", ""))
            if os.path.exists(path):
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name}")
                failures += 1
        elif ctype == "dir_exists":
            path = os.path.join(target, check.get("path", ""))
            if os.path.isdir(path):
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name}")
                failures += 1
        elif ctype == "repo_name_max_length":
            repo_name = os.path.basename(os.path.abspath(target))
            max_len = check.get("max", 25)
            if len(repo_name) <= max_len:
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name} ({repo_name} is {len(repo_name)} chars)")
                failures += 1
        elif ctype == "validate_script":
            script = check.get("script", "")
            arg = check.get("target_arg", "").replace("{target}", target)
            result = subprocess.run(["bash", script, arg], capture_output=True, text=True)
            if result.returncode == 0:
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name}")
                failures += 1
        elif ctype == "file_exists_any":
            paths = check.get("paths", [])
            if any(os.path.exists(os.path.join(target, p)) for p in paths):
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name}")
                failures += 1
        elif ctype == "grep_src":
            pattern = check.get("pattern", "")
            src_dir = os.path.join(target, check.get("dir", "src"))
            result = subprocess.run(["grep", "-r", pattern, src_dir], capture_output=True)
            if result.returncode == 0:
                print(f"  ✓ {rid}: {name}")
            else:
                print(f"  ✗ {rid}: {name}")
                failures += 1
        elif ctype in ("json_field_pattern", "json_key_exists", "file_matches"):
            print(f"  – {rid}: {name} (check type '{ctype}' — skipped)")
        else:
            print(f"  – {rid}: {name} (unknown check type '{ctype}')")

sys.exit(1 if failures > 0 else 0)
PYEOF
