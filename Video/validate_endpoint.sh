#!/usr/bin/env bash

endpoint=$1
graphql_endpoint=${2:-false}
max_time=1
ts_format=${SE_LOG_TIMESTAMP_FORMAT:-"%Y-%m-%d %H:%M:%S,%3N"}
process_name="endpoint.checks"

if [ -n "${SE_ROUTER_USERNAME}" ] && [ -n "${SE_ROUTER_PASSWORD}" ]; then
  BASIC_AUTH="$(echo -en "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64 -w0)"
  BASIC_AUTH="Authorization: Basic ${BASIC_AUTH}"
fi

if [ "${graphql_endpoint}" = "true" ]; then
  endpoint_checks=$(curl --noproxy "*" -m ${max_time} -k -X POST \
    -H "Content-Type: application/json" \
    -H "${BASIC_AUTH}" \
    --data '{"query":"{ grid { sessionCount } }"}' \
    -s "${endpoint}" -o /dev/null -w "%{http_code}")
else
  endpoint_checks=$(curl --noproxy "*" -H "${BASIC_AUTH}" -m ${max_time} -s -k -o /dev/null -w "%{http_code}" "${endpoint}")
fi

if [[ "$endpoint_checks" = "404" ]]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - Endpoint ${endpoint} is not found - status code: ${endpoint_checks}"
elif [[ "$endpoint_checks" = "401" ]]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - Endpoint ${endpoint} requires authentication - status code: ${endpoint_checks}. Please provide valid credentials via SE_ROUTER_USERNAME and SE_ROUTER_PASSWORD environment variables."
elif [[ "$endpoint_checks" != "200" ]]; then
  echo "$(date -u +"${ts_format}") [${process_name}] - Endpoint ${endpoint} is not available - status code: ${endpoint_checks}"
fi
