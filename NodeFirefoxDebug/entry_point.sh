#!/bin/bash

if [ ! -e /opt/selenium/config.json ]; then
  echo No Selenium Node configuration file, the node-base image is not intended to be run directly. 1>&2
  exit 1
fi

if [ -z "$HUB_PORT_4444_TCP_ADDR" ]; then
  echo Not linked with a running Hub container 1>&2
  exit 1
fi

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

# TODO: Look into http://www.seleniumhq.org/docs/05_selenium_rc.jsp#browser-side-logs

# startup tightvnc server
export FONTROOT=/usr/share/fonts/X11
export USER=root
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT"

Xtightvnc $DISPLAY \
    -desktop X \
    -auth /root/.Xauthority \
    -geometry $GEOMETRY \
    -depth $SCREEN_DEPTH \
    -rfbwait 120000 \
    -rfbauth /root/.vnc/passwd \
    -rfbport 5900 \
    -fp $FONTROOT/misc/,$FONTROOT/Type1/,$FONTROOT/75dpi/,$FONTROOT/100dpi/ \
    -co /etc/X11/rgb &

NODE_PID=$!

sleep 1

java -jar /opt/selenium/selenium-server-standalone.jar \
    -role node \
    -hub http://$HUB_PORT_4444_TCP_ADDR:$HUB_PORT_4444_TCP_PORT/grid/register \
    -nodeConfig /opt/selenium/config.json &

fluxbox -display $DISPLAY &

trap shutdown SIGTERM SIGINT
sleep 0.5
wait $NODE_PID

