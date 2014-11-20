  | tee "/tmp/sel-node.log" &
sleep 0.5

fluxbox -display $DISPLAY &

x11vnc -forever -usepw -shared -rfbport 5900 -display $DISPLAY
