#!/bin/bash

probe_name="lifecycle.${1:-"preStop"}"

max_time=3

ID=$(echo $RANDOM)
tmp_node_file="/tmp/nodeProbe${ID}"

function on_exit() {
  rm -rf ${tmp_node_file}
}
trap on_exit EXIT

function init_file() {
  echo "{}" > ${tmp_node_file}
}
init_file

# Set headers if Node Registration Secret is set
if [ ! -z "${SE_REGISTRATION_SECRET}" ]; then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

function is_full_distributed_mode() {
  if [ -n "${SE_DISTRIBUTOR_HOST}" ] && [ -n "${SE_DISTRIBUTOR_PORT}" ]; then
    DISTRIBUTED_MODE=true
    echo "$(date +%FT%T%Z) [${probe_name}] - Detected full distributed mode: ${DISTRIBUTED_MODE}. Since SE_DISTRIBUTOR_HOST and SE_DISTRIBUTOR_PORT are set in Node ConfigMap"
  else
    DISTRIBUTED_MODE=false
    echo "$(date +%FT%T%Z) [${probe_name}] - Detected full distributed mode: ${DISTRIBUTED_MODE}"
  fi
}
is_full_distributed_mode

function get_grid_url() {
  if [ -z "${SE_HUB_HOST:-$SE_ROUTER_HOST}" ] || [ -z "${SE_HUB_PORT:-$SE_ROUTER_PORT}" ]; then
    echo "$(date +%FT%T%Z) [${probe_name}] - There is no configured HUB or ROUTER host. preStop ignores to send drain request to upstream."
    grid_url=""
  fi
  if [ -n "${SE_BASIC_AUTH}" ] && [ "${SE_BASIC_AUTH}" != "*@" ]; then
    SE_BASIC_AUTH="${SE_BASIC_AUTH}@"
  fi
  if [ "${SE_SUB_PATH}" = "/" ]; then
    SE_SUB_PATH=""
  fi
  grid_url=${SE_SERVER_PROTOCOL}://${SE_BASIC_AUTH}${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}${SE_SUB_PATH}
  grid_url_checks=$(curl -m ${max_time} -s -o /dev/null -w "%{http_code}" ${grid_url})
  if [ "${grid_url_checks}" = "401" ]; then
    echo "$(date +%FT%T%Z) [${probe_name}] - Host requires Basic Auth. Please add the credentials to the SE_BASIC_AUTH variable (e.g: user:password). preStop ignores to send drain request to upstream."
    grid_url=""
  fi
  if [ "${grid_url_checks}" = "404" ]; then
    echo "$(date +%FT%T%Z) [${probe_name}] - The Grid is not available or it might have /subPath configured. Please wait a moment or check the SE_SUB_PATH variable if needed."
  fi
}

function signal_distributor_to_drain_node() {
  if [ "${DISTRIBUTED_MODE}" = true ]; then
    echo "$(date +%FT%T%Z) [${probe_name}] - Signaling Distributor to drain node"
    curl -m ${max_time} -k -X POST ${SE_SERVER_PROTOCOL}://${SE_DISTRIBUTOR_HOST}:${SE_DISTRIBUTOR_PORT}/se/grid/distributor/node/${NODE_ID}/drain --header "${HEADERS}"
  fi
}

function signal_hub_to_drain_node() {
  if [ "${DISTRIBUTED_MODE}" = false ]; then
    get_grid_url
    if [ -n "${grid_url}" ]; then
      echo "$(date +%FT%T%Z) [${probe_name}] - Signaling Hub to drain node"
      curl -m ${max_time} -k -X POST ${grid_url}/se/grid/distributor/node/${NODE_ID}/drain --header "${HEADERS}"
    fi
  fi
}

function signal_node_to_drain() {
    echo "$(date +%FT%T%Z) [${probe_name}] - Signaling Node to drain itself"
    curl -m ${max_time} -k -X POST ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/se/grid/node/drain --header "${HEADERS}"
}

if curl -m ${max_time} -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status > ${tmp_node_file}; then
    NODE_ID=$(jq -r '.value.node.nodeId' ${tmp_node_file} || "")
    if [ -n "${NODE_ID}" ]; then
      echo "$(date +%FT%T%Z) [${probe_name}] - Current Node ID is: ${NODE_ID}"
      signal_distributor_to_drain_node
      signal_hub_to_drain_node
      echo
    fi
    signal_node_to_drain
    # Wait for the current session to be finished if any
    while curl -m ${max_time} -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status -o ${tmp_node_file};
    do
      SLOT_HAS_SESSION=$(jq -e ".value.node.slots[]|select(.session != null).id.id" ${tmp_node_file} | tr -d '"' || "")
      if [ -z "${SLOT_HAS_SESSION}" ]; then
        echo "$(date +%FT%T%Z) [${probe_name}] - There is no session running. Node is ready to be terminated."
        echo "$(date +%FT%T%Z) [${probe_name}] - $(cat ${tmp_node_file} || "")"
        echo
        exit 0
      else
        echo "$(date +%FT%T%Z) [${probe_name}] - Node preStop is waiting for current session on slot ${SLOT_HAS_SESSION} to be finished. Node details: message: $(jq -r '.value.message' ${tmp_node_file} || "unknown"), availability: $(jq -r '.value.node.availability' ${tmp_node_file} || "unknown")"
        sleep 1;
      fi
    done
else
    echo "$(date +%FT%T%Z) [${probe_name}] - Node is already drained. Shutting down gracefully!"
fi
