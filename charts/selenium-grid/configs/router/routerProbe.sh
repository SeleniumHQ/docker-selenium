#!/bin/bash

max_time=3
retry_time=3
probe_name="Probe.${1:-"Liveness"}"
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"+%T.%3N"}

if [ -n "${ROUTER_USERNAME}" ] && [ -n "${ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="${ROUTER_USERNAME}:${ROUTER_PASSWORD}@"
fi

if [[ ${SE_SUB_PATH} == */ ]]; then
  GRAPHQL_ENDPOINT="${SE_SUB_PATH}graphql"
else
  GRAPHQL_ENDPOINT="${SE_SUB_PATH}/graphql"
fi

if [[ ${GRAPHQL_ENDPOINT} == /* ]]; then
  GRAPHQL_ENDPOINT="${GRAPHQL_ENDPOINT}"
else
  GRAPHQL_ENDPOINT="/${GRAPHQL_ENDPOINT}"
fi

if [ -z "${SE_GRID_GRAPHQL_URL}" ] && [ -n "${SE_HUB_HOST:-${SE_ROUTER_HOST}}" ] && [ -n "${SE_HUB_PORT:-${SE_ROUTER_PORT}}" ]; then
  SE_GRID_GRAPHQL_URL="${SE_SERVER_PROTOCOL}://${BASIC_AUTH}${SE_HUB_HOST:-${SE_ROUTER_HOST}}:${SE_HUB_PORT:-${SE_ROUTER_PORT}}${GRAPHQL_ENDPOINT}"
elif [ -z "${SE_GRID_GRAPHQL_URL}" ]; then
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - Could not construct GraphQL endpoint, it can be set directly via SE_GRID_GRAPHQL_URL. Bypass the probe checks for now."
  exit 0
fi

GRAPHQL_PRE_CHECK=$(curl --noproxy "*" -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query":"{ grid { sessionCount } }"}' -s -o /dev/null -w "%{http_code}" ${SE_GRID_GRAPHQL_URL})

if [ ${GRAPHQL_PRE_CHECK} -ne 200 ]; then
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - GraphQL endpoint ${SE_GRID_GRAPHQL_URL} is not reachable. Status code: ${GRAPHQL_PRE_CHECK}."
  exit 1
else
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - GraphQL endpoint is healthy."
  exit 0
fi
