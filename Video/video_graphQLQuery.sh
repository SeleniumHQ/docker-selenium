#!/usr/bin/env bash

# Define parameters
SESSION_ID=$1
GRAPHQL_ENDPOINT=${2:-$SE_NODE_GRID_GRAPHQL_URL}
VIDEO_CAP_NAME=${VIDEO_CAP_NAME:-"se:recordVideo"}
TEST_NAME_CAP=${TEST_NAME_CAP:-"se:name"}
VIDEO_FILE_NAME_TRIM=${SE_VIDEO_FILE_NAME_TRIM_REGEX:-"[:alnum:]-_"}
VIDEO_FILE_NAME_SUFFIX=${SE_VIDEO_FILE_NAME_SUFFIX:-"true"}

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
  TEST_NAME=$(jq -r '.data.session.capabilities | fromjson | ."'${TEST_NAME_CAP}'"' /tmp/graphQL_${SESSION_ID}.json)
fi

if [ "${RECORD_VIDEO,,}" = "false" ]; then
  RECORD_VIDEO=false
else
  RECORD_VIDEO=true
fi

if [ "${TEST_NAME}" != "null" ] && [ -n "${TEST_NAME}" ]; then
  if [ "${VIDEO_FILE_NAME_SUFFIX,,}" = "true" ]; then
    TEST_NAME="${TEST_NAME}_${SESSION_ID}"
  fi
  TEST_NAME="$(echo "${TEST_NAME}" | tr ' ' '_' | tr -dc "${VIDEO_FILE_NAME_TRIM}" | cut -c 1-251)"
else
  TEST_NAME="${SESSION_ID}"
fi

return_array=("${RECORD_VIDEO}" "${TEST_NAME}")
echo "${return_array[@]}"
