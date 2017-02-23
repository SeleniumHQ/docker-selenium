#!/bin/bash

source /opt/bin/functions.sh

if [ -z "$HUB_PORT_4444_TCP_ADDR" ]; then
  echo Not linked with a running Hub container 1>&2
  exit 1
fi

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

if [ -z "$IP" ]; then
  IP="$(hostname -i)"
fi


phantomjs --webdriver=$IP:4444 ${PHANTOMJS_OPTS} --webdriver-selenium-grid-hub=http://$HUB_PORT_4444_TCP_ADDR:$HUB_PORT_4444_TCP_PORT

trap shutdown SIGTERM SIGINT
wait $NODE_PID
