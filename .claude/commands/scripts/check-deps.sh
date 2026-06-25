#!/usr/bin/env bash
set -euo pipefail

# check-deps.sh — Verify required local dev services are reachable
# Usage: check-deps.sh <service1> [service2] ...
# Supported: opensearch, elasticsearch, postgres, postgresql, redis

if [[ $# -eq 0 ]]; then
  echo "Usage: check-deps.sh <service> [service...]" >&2
  echo "Supported: opensearch, elasticsearch, postgres, postgresql, redis" >&2
  exit 1
fi

EXIT_CODE=0

for service in "$@"; do
  case "$service" in
    opensearch|elasticsearch)
      if curl -s -o /dev/null -w '' --connect-timeout 2 "http://localhost:9200" 2>/dev/null; then
        echo "${service}: reachable"
      else
        echo "${service}: UNREACHABLE"
        EXIT_CODE=1
      fi
      ;;
    postgres|postgresql)
      if pg_isready -h localhost -p 5432 -t 2 >/dev/null 2>&1; then
        echo "${service}: reachable"
      else
        echo "${service}: UNREACHABLE"
        EXIT_CODE=1
      fi
      ;;
    redis)
      if redis-cli -h localhost ping >/dev/null 2>&1; then
        echo "${service}: reachable"
      else
        echo "${service}: UNREACHABLE"
        EXIT_CODE=1
      fi
      ;;
    *)
      echo "Unknown service: ${service}" >&2
      EXIT_CODE=1
      ;;
  esac
done

exit $EXIT_CODE
