# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/node-firefox-debug:3.7.1-beryllium
LABEL authors=SeleniumHQ

USER seluser

#====================================
# Installation of pulseaudio to support WebRTC with audio streams
#====================================
RUN sudo apt-get update && sudo apt-get install -y pulseaudio

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY entry_point.sh /opt/bin/entry_point.sh

EXPOSE 4444
EXPOSE 5900
