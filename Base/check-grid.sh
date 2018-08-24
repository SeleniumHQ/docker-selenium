#!/usr/bin/env bash
# check-grid.sh

set -e

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        --host)
        HOST="$2"
        if [[ ${HOST} == "" ]]; then HOST="localhost"; fi
        shift 2
        ;;
        --port)
        PORT="$2"
        if [[ ${PORT} == "" ]]; then PORT="4444"; fi
        shift 2
        ;;
        *)
        echoerr "Unknown argument: $1"
        ;;
    esac
done

curl -sSL http://${HOST}:${PORT}/wd/hub/status | jq -r '.value.ready' | grep "true" || exit 1
