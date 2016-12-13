#!/bin/bash

source /opt/bin/functions.sh

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

SERVERNUM=$(get_server_num)

rm -f /tmp/.X*lock

# Use xvfb only if there is not an x server running already
if xset q &>/dev/null; then
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
    ${SE_OPTS} &
else
  xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
    java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
    ${SE_OPTS} &
fi
NODE_PID=$!

trap shutdown SIGTERM SIGINT
wait $NODE_PID
