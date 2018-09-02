#!/bin/bash
#
# IMPORTANT: Change this file only in directory StandaloneDebug!

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

if [ ! -z $VNC_NO_PASSWORD ]; then
    echo "starting VNC server without password authentication"
    X11VNC_OPTS=
else
    X11VNC_OPTS=-usepw
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

rm -f /tmp/.X*lock

# Creating a file descriptor, where the DISPLAY will be saved ("6" was arbitrarily chosen)
exec 6>/tmp/display.log
xvfb-run -a --server-args="-screen 0 $GEOMETRY -ac +extension RANDR -displayfd 6" \
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  ${SE_OPTS} &
NODE_PID=$!
exec 6>&-

trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  sleep 1
  export DISPLAY=:$(cat /tmp/display.log)
  if [ "${DISPLAY}" != ":" ]; then
    echo "Display ${DISPLAY} allocated"
  fi
  xdpyinfo -display ${DISPLAY} >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo "Waiting xvfb..."
done

fluxbox -display ${DISPLAY} &

x11vnc ${X11VNC_OPTS} -forever -shared -rfbport 5900 -display ${DISPLAY} &

wait ${NODE_PID}
