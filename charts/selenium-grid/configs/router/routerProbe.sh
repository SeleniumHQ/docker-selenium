#!/bin/bash

max_time=3
retry_time=3
probe_name="Probe.${1:-"Liveness"}"
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
ROUTER_CONFIG_DIRECTORY=${ROUTER_CONFIG_DIRECTORY:-"/opt/bin"}

GRID_GRAPHQL_URL=$(bash ${ROUTER_CONFIG_DIRECTORY}/routerGraphQLUrl.sh)
BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"

if [ -z "${GRID_GRAPHQL_URL}" ]; then
  echo "$(date -u +"${ts_format}") DEBUG [${probe_name}] - Could not construct GraphQL endpoint, please provide SE_HUB_HOST (or SE_ROUTER_HOST) and SE_HUB_PORT (or SE_ROUTER_PORT). Bypass the probe checks for now."
  exit 0
fi

GRAPHQL_PRE_CHECK=$(curl --noproxy "*" -m ${max_time} -k -X POST -H "Authorization: Basic ${BASIC_AUTH}" -H "Content-Type: application/json" --data '{"query":"{ grid { sessionCount } }"}' -s -o /dev/null -w "%{http_code}" ${GRID_GRAPHQL_URL})

if [ ${GRAPHQL_PRE_CHECK} -ne 200 ]; then
  echo "$(date -u +"${ts_format}") DEBUG [${probe_name}] - GraphQL endpoint is not reachable. Status code: ${GRAPHQL_PRE_CHECK}."
  exit 1
else
  echo "$(date -u +"${ts_format}") DEBUG [${probe_name}] - GraphQL endpoint is healthy."
  exit 0
fi
