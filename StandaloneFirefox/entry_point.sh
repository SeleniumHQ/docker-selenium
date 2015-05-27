#!/bin/bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

[ $# -ne 0 ] && echo "Running with JAVA_OPTS = $* " ]

xvfb-run --server-args="$DISPLAY -screen 0 $GEOMETRY -ac +extension RANDR" \
  java -jar /opt/selenium/selenium-server-standalone.jar $* &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
wait $NODE_PID
