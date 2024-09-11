#!/bin/bash

max_time=3
retry_time=3
probe_name="Probe.${1:-"Liveness"}"
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"+%T.%3N"}
ROUTER_CONFIG_DIRECTORY=${ROUTER_CONFIG_DIRECTORY:-"/opt/bin"}

GRID_GRAPHQL_URL=$(bash ${ROUTER_CONFIG_DIRECTORY}/routerGraphQLUrl.sh)

if [ -z "${GRID_GRAPHQL_URL}" ]; then
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - Could not construct GraphQL endpoint, please provide SE_HUB_HOST (or SE_ROUTER_HOST) and SE_HUB_PORT (or SE_ROUTER_PORT). Bypass the probe checks for now."
  exit 0
fi

GRAPHQL_PRE_CHECK=$(curl --noproxy "*" -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query":"{ grid { sessionCount } }"}' -s -o /dev/null -w "%{http_code}" ${GRID_GRAPHQL_URL})

if [ ${GRAPHQL_PRE_CHECK} -ne 200 ]; then
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - GraphQL endpoint ${GRID_GRAPHQL_URL} is not reachable. Status code: ${GRAPHQL_PRE_CHECK}."
  exit 1
fi

SESSION_QUEUE_SIZE=$(curl --noproxy "*" --retry ${retry_time} -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query":"{ grid { sessionQueueSize } }"}' -s ${GRID_GRAPHQL_URL} | jq -r '.data.grid.sessionQueueSize')

SESSION_COUNT=$(curl --noproxy "*" --retry ${retry_time} -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query": "{ grid { sessionCount } }"}' -s ${GRID_GRAPHQL_URL} | jq -r '.data.grid.sessionCount')

MAX_SESSION=$(curl --noproxy "*" --retry ${retry_time} -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query":"{ grid { maxSession } }"}' -s ${GRID_GRAPHQL_URL} | jq -r '.data.grid.maxSession')

if [ "${SE_LOG_LISTEN_GRAPHQL:-"false"}" = "true" ]; then
  echo "$(curl --noproxy "*" --retry ${retry_time} -m ${max_time} -k -X POST -H "Content-Type: application/json" --data '{"query":"{ grid { sessionCount, maxSession, totalSlots }, nodesInfo { nodes { id, status, sessionCount, maxSession, slotCount, stereotypes, sessions { id, capabilities, slot { id, stereotype } } } }, sessionsInfo { sessionQueueRequests } }"}' -s ${GRID_GRAPHQL_URL} )"
fi

if [ ${SESSION_QUEUE_SIZE} -gt 0 ] && [ ${SESSION_COUNT} -eq 0 ]; then
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - Session Queue Size: ${SESSION_QUEUE_SIZE}, Session Count: ${SESSION_COUNT}, Max Session: ${MAX_SESSION}"
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - It seems the Distributor is delayed in processing a new session in the queue. Probe checks failed."
  exit 1
else
  echo "$(date ${ts_format}) DEBUG [${probe_name}] - Distributor is healthy."
  exit 0
fi
