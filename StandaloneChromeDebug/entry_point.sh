#!/bin/bash

source /opt/bin/clear_x_locks.sh
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
env | cut -f 1 -d "=" | sort > asroot
sudo -E -u seluser -i env | cut -f 1 -d "=" | sort > asseluser
sudo -E -i -u seluser \
  $(for E in $(grep -vxFf asseluser asroot); do echo $E=$(eval echo \$$E); done) \
  DISPLAY=$DISPLAY \
  xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  ${SE_OPTS} &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo Waiting xvfb...
  sleep 0.5
done

fluxbox -display $DISPLAY &

x11vnc -forever -usepw -shared -rfbport 5900 -display $DISPLAY &

wait $NODE_PID
