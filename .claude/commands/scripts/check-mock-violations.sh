#!/usr/bin/env bash
set -euo pipefail

# check-mock-violations.sh — Prevent new test files from mocking constrained services
# Usage: check-mock-violations.sh <base-branch> <constraints-file>
#
# constraints-file: one service pattern per line (e.g., "DatabaseService", "HttpService")

BASE_BRANCH="${1:-}"
CONSTRAINTS_FILE="${2:-}"

if [[ -z "$BASE_BRANCH" || -z "$CONSTRAINTS_FILE" ]]; then
  echo "Usage: check-mock-violations.sh <base-branch> <constraints-file>" >&2
  exit 1
fi

if [[ ! -f "$CONSTRAINTS_FILE" ]]; then
  echo "Constraints file not found: $CONSTRAINTS_FILE (skipping)" >&2
  exit 0
fi

# Find new test files added since base branch
NEW_TEST_FILES=$(git diff --name-only --diff-filter=A "$BASE_BRANCH" -- '*.spec.ts' '*.test.ts' '*.e2e-spec.ts' 2>/dev/null || true)

if [[ -z "$NEW_TEST_FILES" ]]; then
  exit 0
fi

VIOLATIONS=0

while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" == \#* ]] && continue

  while IFS= read -r test_file; do
    [[ -z "$test_file" ]] && continue
    MATCHES=$(grep -n "jest\.\(fn\|mock\|spyOn\).*${pattern}\|${pattern}.*jest\.\(fn\|mock\|spyOn\)" "$test_file" 2>/dev/null || true)
    if [[ -n "$MATCHES" ]]; then
      echo "VIOLATION: $test_file mocks constrained service '$pattern':" >&2
      echo "$MATCHES" >&2
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done <<< "$NEW_TEST_FILES"
done < "$CONSTRAINTS_FILE"

if [[ $VIOLATIONS -gt 0 ]]; then
  echo "${VIOLATIONS} mock violation(s) found" >&2
  exit 1
fi

exit 0
