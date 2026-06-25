#!/usr/bin/env bash
set -euo pipefail

# generate-loop-config.sh — Generate _loop-config.yaml for a target repo
# Usage: generate-loop-config.sh --target <path> [--framework <f>] [--gate-level <g>] [--coverage <n>] [--topology <t>] [--force] [--dry-run]

TARGET=""
FRAMEWORK="jest"
GATE_LEVEL="minimal"
COVERAGE=80
TOPOLOGY="single"
FORCE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --framework) FRAMEWORK="$2"; shift 2 ;;
    --gate-level) GATE_LEVEL="$2"; shift 2 ;;
    --coverage) COVERAGE="$2"; shift 2 ;;
    --topology) TOPOLOGY="$2"; shift 2 ;;
    --force) FORCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo "ERROR: --target is required" >&2
  exit 1
fi

# Validate enums
case "$FRAMEWORK" in
  jest|vitest|mocha|pytest|go-test) ;;
  *) echo "ERROR: Invalid framework: $FRAMEWORK (must be jest|vitest|mocha|pytest|go-test)" >&2; exit 1 ;;
esac

case "$GATE_LEVEL" in
  minimal|standard|full) ;;
  *) echo "ERROR: Invalid gate-level: $GATE_LEVEL (must be minimal|standard|full)" >&2; exit 1 ;;
esac

case "$TOPOLOGY" in
  single|multi-module) ;;
  *) echo "ERROR: Invalid topology: $TOPOLOGY (must be single|multi-module)" >&2; exit 1 ;;
esac

OUTPUT_FILE="${TARGET}/_loop-config.yaml"

if [[ -f "$OUTPUT_FILE" && "$FORCE" != "true" ]]; then
  echo "ERROR: ${OUTPUT_FILE} already exists. Use --force to overwrite." >&2
  exit 1
fi

CONFIG="version: \"1.0\"
playbooks:
  - datastore-schema-modeling
test:
  framework: ${FRAMEWORK}
  coverage_threshold: ${COVERAGE}
gates:
  default_level: ${GATE_LEVEL}
compliance:
  rules: [SEC-001, SEC-002, PLAT-001]
topology:
  mode: ${TOPOLOGY}
commit:
  format: conventional
"

if [[ "$DRY_RUN" == "true" ]]; then
  echo "$CONFIG"
  exit 0
fi

mkdir -p "$TARGET"
echo "$CONFIG" > "$OUTPUT_FILE"
echo "Generated: ${OUTPUT_FILE}"

# Validate immediately
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/validate-loop-config.sh" ]]; then
  bash "${SCRIPT_DIR}/validate-loop-config.sh" "$OUTPUT_FILE"
fi
