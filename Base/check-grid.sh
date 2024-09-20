#!/usr/bin/env bash
# check-grid.sh

set -e

HOST="localhost"
PORT="4444"
BASIC_AUTH="$(echo -n "${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD}" | base64)"

echoerr() { echo "$@" 1>&2; }

# process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  --host)
    HOST=${2:-"localhost"}
    shift 2
    ;;
  --port)
    PORT=${2:-"4444"}
    shift 2
    ;;
  *)
    echoerr "Unknown argument: $1"
    exit 1
    ;;
  esac
done

curl -skSL -H "Authorization: Basic ${BASIC_AUTH}" ${SE_SERVER_PROTOCOL:-"http"}://${HOST}:${PORT}/wd/hub/status | jq -r '.value.ready' | grep -q "true" || exit 1
