ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

# Inputs: heads, tags
ARG NOVNC_SOURCE="heads"
# Inputs: master, "v1.4.0"
ARG NOVNC_VERSION="master"
# Inputs: heads, tags
ARG WEBSOCKIFY_SOURCE="heads"
# Inputs: master, "v0.11.0"
ARG WEBSOCKIFY_VERSION="master"

USER root

#==============
# Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    xvfb \
    xauth \
    pulseaudio \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==============================
# Locale and encoding settings
#==============================
ENV LANG_WHICH en
ENV LANG_WHERE US
ENV ENCODING UTF-8
ENV LANGUAGE ${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
ENV LANG ${LANGUAGE}
# Layer size: small: ~9 MB
# Layer size: small: ~9 MB MB (with --no-install-recommends)
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en \
    tzdata \
    locales \
  && locale-gen ${LANGUAGE} \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get -qyy autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

#=====
# VNC
#=====
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
  x11vnc x11-utils \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fluxbox eterm hsetroot feh \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#================
# Font libraries
#================
# libfontconfig            ~1 MB
# libfreetype6             ~1 MB
# xfonts-cyrillic          ~2 MB
# xfonts-scalable          ~2 MB
# fonts-liberation         ~3 MB
# fonts-ipafont-gothic     ~13 MB
# fonts-wqy-zenhei         ~17 MB
# fonts-tlwg-loma-otf      ~300 KB
# fonts-ubuntu             ~5 MB
#   Ubuntu Font Family, sans-serif typeface hinted for clarity
# Removed packages:
# xfonts-100dpi            ~6 MB
# xfonts-75dpi             ~6 MB
# fonts-noto-color-emoji   ~10 MB
# Regarding fonts-liberation see:
#  https://github.com/SeleniumHQ/docker-selenium/issues/383#issuecomment-278367069
# Layer size: small: 50.3 MB (with --no-install-recommends)
# Layer size: small: 50.3 MB
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    libfontconfig \
    libfreetype6 \
    xfonts-cyrillic \
    xfonts-scalable \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-tlwg-loma-otf \
    fonts-ubuntu \
    fonts-noto-color-emoji \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean

########################################
# noVNC exposes VNC through a web page #
########################################
RUN  wget -nv -O noVNC.zip \
       "https://github.com/novnc/noVNC/archive/refs/${NOVNC_SOURCE}/${NOVNC_VERSION}.zip" \
  && unzip -x noVNC.zip \
  && mv noVNC-${NOVNC_VERSION} /opt/bin/noVNC \
  && cp /opt/bin/noVNC/vnc.html /opt/bin/noVNC/index.html \
  && rm noVNC.zip \
  && wget -nv -O websockify.zip \
      "https://github.com/novnc/websockify/archive/refs/${WEBSOCKIFY_SOURCE}/${WEBSOCKIFY_VERSION}.zip" \
  && unzip -x websockify.zip \
  && rm websockify.zip \
  && mv websockify-${WEBSOCKIFY_VERSION} /opt/bin/noVNC/utils/websockify \
  && rm -rf /opt/bin/noVNC/utils/websockify/docker /opt/bin/noVNC/utils/websockify/tests

#=========================================================================================================================================
# Run this command for executable file permissions for /dev/shm when this is a "child" container running in Docker Desktop and WSL2 distro
#=========================================================================================================================================
RUN chmod +x /dev/shm

# Creating base directory for Xvfb
RUN mkdir -p /tmp/.X11-unix

#==============================
# Generating the VNC password using initial password in Base image
# Changing ownership to ${SEL_USER}, so the service can be started
#==============================

RUN mkdir -p ${HOME}/.vnc \
    && x11vnc -storepasswd $(cat /opt/selenium/initialPasswd) ${HOME}/.vnc/passwd \
    && chown -R "${SEL_USER}:${SEL_GROUP}" ${HOME}/.vnc

#==========
# Relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN chmod -R 775 ${HOME} /tmp/.X11-unix \
  && chgrp -R 0 ${HOME} /tmp/.X11-unix \
  && chmod -R g=u ${HOME} /tmp/.X11-unix

#============================================
# Shared cleanup script environment variables
#============================================
ENV SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP false
ENV SE_BROWSER_LEFTOVERS_INTERVAL_SECS 3600
ENV SE_BROWSER_LEFTOVERS_PROCESSES_SECS 7200
ENV SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS 1

#===================================================
# Run the following commands as non-privileged user
#===================================================

USER ${SEL_UID}

#==============================
# Scripts to run Selenium Node and XVFB
#==============================
COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-node.sh \
      start-xvfb.sh \
      /opt/bin/

#==============================
# Supervisor configuration file
#==============================
COPY selenium.conf /etc/supervisor/conf.d/

#==============================
# Scripts to run fluxbox, x11vnc and noVNC
#==============================
COPY --chown="${SEL_UID}:${SEL_GID}" start-vnc.sh \
      start-novnc.sh \
      /opt/bin/

#==============================
# Selenium Grid logo as wallpaper for Fluxbox
#==============================
COPY selenium_grid_logo.png /usr/share/images/fluxbox/ubuntu-light.png

#============================
# Some configuration options
#============================
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_SCREEN_DEPTH 24
ENV SE_SCREEN_DPI 96
ENV SE_START_XVFB true
ENV SE_START_VNC true
ENV SE_START_NO_VNC true
ENV SE_NO_VNC_PORT 7900
ENV SE_VNC_PORT 5900
ENV DISPLAY :99.0
ENV DISPLAY_NUM 99
# Path to the Configfile
ENV CONFIG_FILE=/opt/selenium/config.toml
ENV GENERATE_CONFIG true
# Drain the Node after N sessions. 
# A value higher than zero enables the feature
ENV SE_DRAIN_AFTER_SESSION_COUNT 0
# Setting Selenium Manager to work offline
ENV SE_OFFLINE true

#========================
# Selenium Configuration
#========================
# As integer, maps to "max-concurrent-sessions"
ENV SE_NODE_MAX_SESSIONS 1
# As integer, maps to "session-timeout" in seconds
ENV SE_NODE_SESSION_TIMEOUT 300
# As boolean, maps to "override-max-sessions"
ENV SE_NODE_OVERRIDE_MAX_SESSIONS false
# As integer, maps to "--heartbeat-period" in seconds
ENV SE_NODE_HEARTBEAT_PERIOD 30

# Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
ENV DBUS_SESSION_BUS_ADDRESS=/dev/null
ENV SE_OTEL_SERVICE_NAME "selenium-node"

# Copying configuration script generator
COPY --chown="${SEL_UID}:${SEL_GID}" generate_config /opt/bin/generate_config

EXPOSE 5900
