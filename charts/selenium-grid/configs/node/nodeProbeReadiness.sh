#!/usr/bin/env bash

probe_name="Probe.${1:-"Readiness"}"
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
ENDPOINT="${SE_SERVER_PROTOCOL:-"http"}://localhost:${SE_NODE_PORT:-"5555"}/status"

response=$(curl -skSL --noproxy "*" "${ENDPOINT}")

# Validate the JSON response
# From v4.31.0 - [grid] Expose register status via Node status response (#15448)
if echo "$response" | jq -e '.value.registered == true' > /dev/null; then
  echo "$(date -u +"${ts_format}") [${probe_name}] - Readiness check passed: Node is registered."
else
  echo "$(date -u +"${ts_format}") [${probe_name}] - Readiness check failed: Node is not registered."
  exit 1
fi
