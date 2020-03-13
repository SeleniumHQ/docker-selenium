#!/bin/bash

/opt/bin/generate_config > /opt/selenium/config.json

# Start the pulseaudio server
pulseaudio -D --exit-idle-time=-1

# Load the virtual sink and set it as default
pacmd load-module module-virtual-sink sink_name=v1
pacmd set-default-sink v1

# set the monitor of v1 sink to be the default source
pacmd set-default-source v1.monitor

rm -f /tmp/.X*lock

java -jar /opt/selenium/selenium-server.jar node --publish-events tcp://"$HUB_HOST":4442 \
  --subscribe-events tcp://"$HUB_HOST":4443
