#!/usr/bin/env bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export CONTAINER_IP=$(ip addr show dev eth0 | grep "inet " | awk '{print $2}' | cut -d '/' -f 1)
export DOCKER_HOST_IP=$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')
export VNC_PORT=5900
export XVFB_LOG="/tmp/Xvfb_headless.log"
export FLUXBOX_LOG="/tmp/fluxbox_manager.log"
export VNC_LOG="/tmp/x11vnc_forever.log"
export XTERMINAL_HUB_LOG="/tmp/sel-hub.log"
export XTERMINAL_NODE_LOG="/tmp/sel-node.log"

# As of docker >= 1.2.0 is possible to append our stuff directly into /etc/hosts
cat /tmp/hosts >> /etc/hosts
echo "docker.host.dev   $DOCKER_HOST_IP" >> /etc/hosts
echo "docker.guest.dev  $CONTAINER_IP"   >> /etc/hosts

# Start the X server that can run on machines with no display 
# hardware and no physical input devices
/usr/bin/Xvfb $DISPLAY -screen 0 $GEOMETRY -ac >$XVFB_LOG 2>&1  &
sleep 0.5

# A fast, lightweight and responsive window manager
fluxbox -display $DISPLAY >$FLUXBOX_LOG 2>&1  &

# Start a GUI xTerm to help debugging when VNC into the container
x-terminal-emulator -geometry 120x40+10+10 -ls -title "x-terminal-emulator" &

# Start a GUI xTerm to easily debug the headless instance
x-terminal-emulator -geometry 100x30-10+10 -ls -title "sel-hub" \
    -e "/opt/selenium/sel-hub.sh" 2>&1 | tee $XTERMINAL_HUB_LOG  &

x-terminal-emulator -geometry 100x30-10-20 -ls -title "sel-node" \
    -e "/opt/selenium/sel-node.sh" 2>&1 | tee $XTERMINAL_NODE_LOG  &

# Start VNC server to enable viewing what's going on but not mandatory
x11vnc -forever -usepw -shared -rfbport $VNC_PORT -display $DISPLAY >$VNC_LOG 2>&1
