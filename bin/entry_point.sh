#!/usr/bin/env bash
export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
export CONTAINER_IP=$(ip addr show dev eth0 | grep "inet " | awk '{print $2}' | cut -d '/' -f 1)
export DOCKER_HOST_IP=$(netstat -nr | grep '^0\.0\.0\.0' | awk '{print $2}')

# Start the X server that can run on machines with no display 
# hardware and no physical input devices
/usr/bin/Xvfb $DISPLAY -screen 0 $GEOMETRY -ac &
sleep 0.5

# A fast, lightweight and responsive window manager
fluxbox -display $DISPLAY &

# Start a GUI xTerm to help debugging when VNC into the container
x-terminal-emulator -geometry 120x40+10+10 -ls -title "x-terminal-emulator" &
sleep 0.5

# Start a GUI xTerm to easily debug the headless instance
x-terminal-emulator -geometry 100x30+10+10 -ls -title "local-sel-headless" \
    -e "/opt/selenium/local-sel-headless.sh" &

# Start VNC server to enable viewing what's going on but not mandatory
x11vnc -forever -usepw -display $DISPLAY
