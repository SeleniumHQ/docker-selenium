#!/bin/bash

ROOT=/opt/selenium
CONF=$ROOT/config.json

$ROOT/generate_config >$CONF
echo "starting selenium hub with configuration:"
cat $CONF

function shutdown {
    echo "shutting down hub.."
    kill -s SIGTERM $NODE_PID
    wait $NODE_PID
    echo "shutdown complete"
}

java -jar /opt/selenium/selenium-server-standalone.jar \
  ${JAVA_OPTS} \
  -role hub \
  -hubConfig $CONF &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
wait $NODE_PID

