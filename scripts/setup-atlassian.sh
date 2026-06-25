#!/usr/bin/env bash
set -euo pipefail

# setup-atlassian.sh — Install Atlassian CLI, collect credentials, verify connectivity
# Usage: setup-atlassian.sh [--email EMAIL] [--site SITE] [--confluence-url URL]

EMAIL=""
SITE="https://your-org.atlassian.net"
CONFLUENCE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --email) EMAIL="$2"; shift 2 ;;
    --site) SITE="$2"; shift 2 ;;
    --confluence-url) CONFLUENCE_URL="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

CONFLUENCE_URL="${CONFLUENCE_URL:-${SITE}/wiki}"

echo "=== Atlassian CLI Setup ==="

# Platform-specific install
case "$(uname -s)" in
  Darwin)
    if ! command -v acli >/dev/null 2>&1; then
      echo "Installing Atlassian CLI via Homebrew..."
      brew install atlassian-cli 2>/dev/null || echo "WARN: brew install failed — install manually"
    fi
    ;;
  Linux)
    if ! command -v acli >/dev/null 2>&1; then
      echo "Installing Atlassian CLI to ~/.local/bin/..."
      mkdir -p ~/.local/bin
      echo "NOTE: Download acli from the vendor and place in ~/.local/bin/"
    fi
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows detected. Please install Atlassian CLI manually."
    echo "See: https://developer.atlassian.com/cloud/jira/platform/rest/"
    exit 0
    ;;
esac

# Collect credentials
if [[ -z "$EMAIL" ]]; then
  read -rp "Atlassian email: " EMAIL
fi

read -rsp "Atlassian API token: " TOKEN
echo

TEST_ISSUE=""
read -rp "Test Jira issue key (e.g., PROJ-1): " TEST_ISSUE

# Write .env.acli.local
ENV_FILE=".env.acli.local"
cat > "$ENV_FILE" << EOF
ATLASSIAN_JIRA_BASE_URL=${SITE}
ATLASSIAN_JIRA_USER=${EMAIL}
ATLASSIAN_JIRA_TOKEN=${TOKEN}
ATLASSIAN_CONFLUENCE_BASE_URL=${CONFLUENCE_URL}
ATLASSIAN_CONFLUENCE_USER=${EMAIL}
ATLASSIAN_CONFLUENCE_TOKEN=${TOKEN}
ACLI_TEST_JIRA_ISSUE=${TEST_ISSUE}
EOF

chmod 600 "$ENV_FILE"
echo "Credentials written to ${ENV_FILE} (mode 600)"

# Verify Jira connectivity
echo "Testing Jira connectivity..."
JIRA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${EMAIL}:${TOKEN}" \
  "${SITE}/rest/api/3/myself" 2>/dev/null || echo "000")

if [[ "$JIRA_RESPONSE" == "200" ]]; then
  echo "✓ Jira authentication successful"
else
  echo "✗ Jira authentication failed (HTTP ${JIRA_RESPONSE})"
fi

# Verify Confluence connectivity
echo "Testing Confluence connectivity..."
CONF_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "${EMAIL}:${TOKEN}" \
  "${CONFLUENCE_URL}/rest/api/space?limit=1" 2>/dev/null || echo "000")

if [[ "$CONF_RESPONSE" == "200" ]]; then
  echo "✓ Confluence authentication successful"
else
  echo "✗ Confluence authentication failed (HTTP ${CONF_RESPONSE})"
fi

echo "=== Setup complete ==="
