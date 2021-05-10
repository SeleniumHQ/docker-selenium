#!/usr/bin/env bash
# check-grid.sh

set -e

HOST="localhost"
PORT="4444"

echoerr() { echo "$@" 1>&2; }

# process arguments
while [[ $# -gt 0 ]]
do
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

curl -sSL http://${HOST}:${PORT}/wd/hub/status | jq -r '.value.ready' | grep -q "true" || exit 1
