#!/usr/bin/env bash
set -euo pipefail

# test-acli.sh — Smoke-test Atlassian CLI connectivity
# Usage: test-acli.sh [--jira-issue PROJ-1] [--confluence-page PAGE_ID]

JIRA_ISSUE=""
CONFLUENCE_PAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jira-issue) JIRA_ISSUE="$2"; shift 2 ;;
    --confluence-page) CONFLUENCE_PAGE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Source credentials
ENV_FILE=".env.acli.local"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: $ENV_FILE not found. Run ./scripts/setup-atlassian.sh first." >&2
  exit 1
fi
source "$ENV_FILE"

JIRA_ISSUE="${JIRA_ISSUE:-${ACLI_TEST_JIRA_ISSUE:-}}"
FAILURES=0

echo "=== Atlassian Connectivity Tests ==="

# Check 1: CLI binary
echo -n "1. CLI binary... "
if command -v acli >/dev/null 2>&1; then
  echo "✓ found"
else
  echo "✗ not found"
  echo "   Install: brew install atlassian-cli (macOS) or download binary"
  FAILURES=$((FAILURES + 1))
fi

# Check 2: Jira issue query
echo -n "2. Jira query... "
if [[ -z "$JIRA_ISSUE" ]]; then
  echo "– skipped (no test issue configured)"
else
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${ATLASSIAN_JIRA_USER}:${ATLASSIAN_JIRA_TOKEN}" \
    "${ATLASSIAN_JIRA_BASE_URL}/rest/api/3/issue/${JIRA_ISSUE}" 2>/dev/null || echo "000")
  if [[ "$RESPONSE" == "200" ]]; then
    echo "✓ fetched ${JIRA_ISSUE}"
  else
    echo "✗ failed (HTTP ${RESPONSE})"
    echo "   Check: ATLASSIAN_JIRA_USER, ATLASSIAN_JIRA_TOKEN, ATLASSIAN_JIRA_BASE_URL"
    FAILURES=$((FAILURES + 1))
  fi
fi

# Check 3: Confluence REST
echo -n "3. Confluence REST... "
if [[ -z "${ATLASSIAN_CONFLUENCE_BASE_URL:-}" ]]; then
  echo "✗ ATLASSIAN_CONFLUENCE_BASE_URL not set in $ENV_FILE"
  FAILURES=$((FAILURES + 1))
else
  ENDPOINT="${ATLASSIAN_CONFLUENCE_BASE_URL}/rest/api/space?limit=1"
  if [[ -n "$CONFLUENCE_PAGE" ]]; then
    ENDPOINT="${ATLASSIAN_CONFLUENCE_BASE_URL}/rest/api/content/${CONFLUENCE_PAGE}"
  fi
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${ATLASSIAN_CONFLUENCE_USER}:${ATLASSIAN_CONFLUENCE_TOKEN}" \
    "$ENDPOINT" 2>/dev/null || echo "000")
  if [[ "$RESPONSE" == "200" ]]; then
    echo "✓ connected"
  else
    echo "✗ failed (HTTP ${RESPONSE})"
    echo "   Check: ATLASSIAN_CONFLUENCE_USER, ATLASSIAN_CONFLUENCE_TOKEN, ATLASSIAN_CONFLUENCE_BASE_URL"
    FAILURES=$((FAILURES + 1))
  fi
fi

echo ""
if [[ $FAILURES -eq 0 ]]; then
  echo "All checks passed."
  exit 0
else
  echo "${FAILURES} check(s) failed."
  exit 1
fi
