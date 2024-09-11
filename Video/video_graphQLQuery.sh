#!/usr/bin/env bash

max_time=1
retry_time=3

# Define parameters
SESSION_ID=$1
if [ -n "${SE_NODE_GRID_GRAPHQL_URL}" ]; then
  GRAPHQL_ENDPOINT=${SE_NODE_GRID_GRAPHQL_URL}
else
  GRAPHQL_ENDPOINT="$(/opt/bin/video_gridUrl.sh)"
fi
if [[ -n ${GRAPHQL_ENDPOINT} ]] && [[ ! ${GRAPHQL_ENDPOINT} == */graphql ]]; then
  GRAPHQL_ENDPOINT="${GRAPHQL_ENDPOINT}/graphql"
fi

VIDEO_CAP_NAME=${VIDEO_CAP_NAME:-"se:recordVideo"}
TEST_NAME_CAP=${TEST_NAME_CAP:-"se:name"}
VIDEO_NAME_CAP=${VIDEO_NAME_CAP:-"se:videoName"}
VIDEO_FILE_NAME_TRIM=${SE_VIDEO_FILE_NAME_TRIM_REGEX:-"[:alnum:]-_"}
VIDEO_FILE_NAME_SUFFIX=${SE_VIDEO_FILE_NAME_SUFFIX:-"true"}
poll_interval=${SE_VIDEO_POLL_INTERVAL:-1}

if [ -n "${GRAPHQL_ENDPOINT}" ]; then
  current_check=1
  while true; do
    # Send GraphQL query
    endpoint_checks=$(curl --noproxy "*" -m ${max_time} -k -X POST \
      -H "Content-Type: application/json" \
      --data '{"query":"{ session (id: \"'${SESSION_ID}'\") { id, capabilities, startTime, uri, nodeId, nodeUri, sessionDurationMillis, slot { id, stereotype, lastStarted } } } "}' \
      -s "${GRAPHQL_ENDPOINT}" -o "/tmp/graphQL_${SESSION_ID}.json" -w "%{http_code}")
    current_check=$((current_check + 1))
    # Check if the response contains "capabilities"
    if [[ "$endpoint_checks" = "404" ]] || [[ $current_check -eq $retry_time ]]; then
      break
    elif [[ "$endpoint_checks" = "200" ]] && [[ $(jq -e '.data.session.capabilities | fromjson | ."'se:vncEnabled'"' /tmp/graphQL_${SESSION_ID}.json >/dev/null) -eq 0 ]]; then
      break
    fi
    sleep ${poll_interval}
  done

  if [[ -f "/tmp/graphQL_${SESSION_ID}.json" ]]; then
    # Extract the values from the response
    RECORD_VIDEO=$(jq -r '.data.session.capabilities | fromjson | ."'${VIDEO_CAP_NAME}'"' /tmp/graphQL_${SESSION_ID}.json)
    TEST_NAME=$(jq -r '.data.session.capabilities | fromjson | ."'${TEST_NAME_CAP}'"' /tmp/graphQL_${SESSION_ID}.json)
    VIDEO_NAME=$(jq -r '.data.session.capabilities | fromjson | ."'${VIDEO_NAME_CAP}'"' /tmp/graphQL_${SESSION_ID}.json)
  fi
fi

# Check if enabling to record video
if [ "${RECORD_VIDEO,,}" = "false" ]; then
  RECORD_VIDEO=false
else
  RECORD_VIDEO=true
fi

# Check if video file name is set via capabilities
if [ "${VIDEO_NAME}" != "null" ] && [ -n "${VIDEO_NAME}" ]; then
  TEST_NAME="${VIDEO_NAME}"
elif [ "${TEST_NAME}" != "null" ] && [ -n "${TEST_NAME}" ]; then
  TEST_NAME="${TEST_NAME}"
else
  TEST_NAME=""
fi

# Check if append session ID to the video file name suffix
if [ -z "${TEST_NAME}" ]; then
  TEST_NAME="${SESSION_ID}"
elif [ "${VIDEO_FILE_NAME_SUFFIX,,}" = "true" ]; then
  TEST_NAME="${TEST_NAME}_${SESSION_ID}"
fi

# Normalize the video file name
TEST_NAME="$(echo "${TEST_NAME}" | tr ' ' '_' | tr -dc "${VIDEO_FILE_NAME_TRIM}" | cut -c 1-251)"

return_array=("${RECORD_VIDEO}" "${TEST_NAME}")

# stdout the values for other scripts consuming
echo "${return_array[@]}"
