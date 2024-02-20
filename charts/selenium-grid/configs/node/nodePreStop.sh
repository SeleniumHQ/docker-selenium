#!/bin/bash

function on_exit() {
  rm -rf /tmp/preStopOutput
}
trap on_exit EXIT

# Set headers if Node Registration Secret is set
if [ ! -z "${SE_REGISTRATION_SECRET}" ];
then
  HEADERS="X-REGISTRATION-SECRET: ${SE_REGISTRATION_SECRET}"
else
  HEADERS="X-REGISTRATION-SECRET;"
fi

function is_full_distributed_mode() {
  if [ -n "${SE_DISTRIBUTOR_HOST}" ] && [ -n "${SE_DISTRIBUTOR_PORT}" ]; then
    DISTRIBUTED_MODE=true
    echo "Detected full distributed mode: ${DISTRIBUTED_MODE}. Since SE_DISTRIBUTOR_HOST and SE_DISTRIBUTOR_PORT are set in Node ConfigMap"
  else
    DISTRIBUTED_MODE=false
    echo "Detected full distributed mode: ${DISTRIBUTED_MODE}"
  fi
}
is_full_distributed_mode

function signal_distributor_to_drain_node() {
  if [ "${DISTRIBUTED_MODE}" = true ]; then
    echo "Signaling Distributor to drain node"
    set -x
    curl -k -X POST ${SE_SERVER_PROTOCOL}://${SE_DISTRIBUTOR_HOST}:${SE_DISTRIBUTOR_PORT}/se/grid/distributor/node/${NODE_ID}/drain --header "${HEADERS}"
    set +x
  fi
}

function signal_hub_to_drain_node() {
  if [ "${DISTRIBUTED_MODE}" = false ]; then
    echo "Signaling Hub to drain node"
    curl -k -X POST ${SE_GRID_URL}/se/grid/distributor/node/${NODE_ID}/drain --header "${HEADERS}"
  fi
}

function signal_node_to_drain() {
    echo "Signaling Node to drain itself"
    curl -k -X POST ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/se/grid/node/drain --header "${HEADERS}"
}

function replace_localhost_by_service_name() {
  internal="${SE_HUB_HOST:-$SE_ROUTER_HOST}:${SE_HUB_PORT:-$SE_ROUTER_PORT}"
  echo "SE_NODE_GRID_URL: ${SE_NODE_GRID_URL}"
  if [[ "${SE_NODE_GRID_URL}" == *"/localhost"* ]]; then
      SE_GRID_URL=${SE_NODE_GRID_URL//localhost/${internal}}
  elif [[ "${SE_NODE_GRID_URL}" == *"/127.0.0.1"* ]]; then
      SE_GRID_URL=${SE_NODE_GRID_URL//127.0.0.1/${internal}}
  elif [[ "${SE_NODE_GRID_URL}" == *"/0.0.0.0"* ]]; then
      SE_GRID_URL=${SE_NODE_GRID_URL//0.0.0.0/${internal}}
  else
      SE_GRID_URL=${SE_NODE_GRID_URL}
  fi
  echo "Set SE_GRID_URL internally: ${SE_GRID_URL}"
}
replace_localhost_by_service_name

if curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status > /tmp/preStopOutput; then
    NODE_ID=$(jq -r '.value.node.nodeId' /tmp/preStopOutput)
    if [ -n "${NODE_ID}" ]; then
      echo "Current Node ID is: ${NODE_ID}"
      signal_hub_to_drain_node
      signal_distributor_to_drain_node
      echo
    fi
    signal_node_to_drain
    # Wait for the current session to be finished if any
    while curl -sfk ${SE_SERVER_PROTOCOL}://127.0.0.1:${SE_NODE_PORT}/status -o /tmp/preStopOutput;
    do
      echo "Node preStop is waiting for current session to be finished if any. Node details: message: $(jq -r '.value.message' /tmp/preStopOutput || "unknown"), availability: $(jq -r '.value.node.availability' /tmp/preStopOutput || "unknown")"
      sleep 1;
    done
else
    echo "Node is already drained. Shutting down gracefully!"
fi
