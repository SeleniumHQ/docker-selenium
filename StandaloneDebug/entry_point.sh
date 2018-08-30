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

xvfb-run -a --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  ${SE_OPTS} &
NODE_PID=$!

trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  DISPLAY=$(xvfb-run printenv DISPLAY)
  if [ -z "$DISPLAY" ]; then
    echo "\$DISPLAY env variable is empty"
    break
  fi
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo Waiting xvfb...
  sleep 0.5
done

fluxbox -display $DISPLAY &

x11vnc $X11VNC_OPTS -forever -shared -rfbport 5900 -display $DISPLAY &

wait $NODE_PID
