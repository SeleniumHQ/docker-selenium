#!/usr/bin/env bash

# Define parameters
SESSION_ID=$1
GRAPHQL_ENDPOINT=${2:-$SE_NODE_GRID_GRAPHQL_URL}
VIDEO_CAP_NAME=${VIDEO_CAP_NAME:-"se:recordVideo"}

if [ -z "${GRAPHQL_ENDPOINT}" ] && [ -n "${SE_NODE_GRID_URL}" ]; then
  GRAPHQL_ENDPOINT="${SE_NODE_GRID_URL}/graphql"
fi

if [ -n "${GRAPHQL_ENDPOINT}" ]; then
  # Send GraphQL query
  curl --retry 3 -k -X POST \
    -H "Content-Type: application/json" \
    --data '{"query":"{ session (id: \"'${SESSION_ID}'\") { id, capabilities, startTime, uri, nodeId, nodeUri, sessionDurationMillis, slot { id, stereotype, lastStarted } } } "}' \
    -s "${GRAPHQL_ENDPOINT}" > /tmp/graphQL_${SESSION_ID}.json

  RECORD_VIDEO=$(jq -r '.data.session.capabilities | fromjson | ."'${VIDEO_CAP_NAME}'"' /tmp/graphQL_${SESSION_ID}.json)
fi

if [ "${RECORD_VIDEO,,}" = "false" ]; then
  echo "${RECORD_VIDEO,,}"
else
  echo true
fi
