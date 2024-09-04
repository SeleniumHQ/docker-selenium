ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

# Inputs: heads, tags
ARG NOVNC_SOURCE="heads"
# Inputs: master, "v1.4.0"
ARG NOVNC_VERSION="master"
# Inputs: heads, tags
ARG WEBSOCKIFY_SOURCE="heads"
# Inputs: master, "v0.11.0"
ARG WEBSOCKIFY_VERSION="master"
ARG LANG_WHICH=en
ARG LANG_WHERE=US
ARG ENCODING=UTF-8
ARG LANGUAGE=${LANG_WHICH}_${LANG_WHERE}.${ENCODING}

USER root

#==============================
# Locale and encoding settings
#==============================
ENV LANG_WHICH=${LANG_WHICH} \
    LANG_WHERE=${LANG_WHERE} \
    ENCODING=${ENCODING} \
    LANGUAGE=${LANGUAGE} \
    LANG=${LANGUAGE} \
#============================================
# Shared cleanup script environment variables
#============================================
    SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP=false \
    SE_BROWSER_LEFTOVERS_INTERVAL_SECS=3600 \
    SE_BROWSER_LEFTOVERS_PROCESSES_SECS=7200 \
    SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS=1 \
#========================
# Selenium Configuration
#========================
    # Drain the Node after N sessions (a value higher than zero enables the feature)
    SE_DRAIN_AFTER_SESSION_COUNT=0 \
    SE_NODE_MAX_SESSIONS=1 \
    SE_NODE_SESSION_TIMEOUT=300 \
    SE_NODE_OVERRIDE_MAX_SESSIONS=false \
    SE_NODE_HEARTBEAT_PERIOD=30 \
    SE_OTEL_SERVICE_NAME="selenium-node" \
    # Setting Selenium Manager to work offline
    SE_OFFLINE=true \
#============================
# Some configuration options
#============================
    SE_SCREEN_WIDTH=1920 \
    SE_SCREEN_HEIGHT=1080 \
    SE_SCREEN_DEPTH=24 \
    SE_SCREEN_DPI=96 \
    SE_START_XVFB=true \
    SE_START_VNC=true \
    SE_START_NO_VNC=true \
    SE_NO_VNC_PORT=7900 \
    SE_VNC_PORT=5900 \
    DISPLAY=:99.0 \
    DISPLAY_NUM=99 \
    # Path to the Configfile
    CONFIG_FILE=/opt/selenium/config.toml \
    GENERATE_CONFIG=true \
    # Following line fixes https://github.com/SeleniumHQ/docker-selenium/issues/87
    DBUS_SESSION_BUS_ADDRESS=/dev/null

RUN --mount=type=secret,id=SEL_PASSWD \
  apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
#==============
# Xvfb
#==============
    xvfb \
    libxcb1 \
    xauth \
    pulseaudio \
#=====
# VNC
#=====
    x11vnc x11-utils \
#=========
# Fluxbox (a fast, lightweight and responsive window manager)
#=========
    fluxbox eterm hsetroot feh \
#==============================
# Locale and encoding settings
#==============================
    language-pack-en \
    locales \
    libfontconfig \
    libfreetype6 \
    xfonts-scalable \
    xfonts-cyrillic \
    fonts-ubuntu \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-tlwg-loma-otf \
    fonts-noto-color-emoji \
  && locale-gen ${LANGUAGE} \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get -qyy autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -qyy clean \
########################################
# noVNC exposes VNC through a web page #
########################################
  && wget -nv -O noVNC.zip \
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
  && rm -rf /opt/bin/noVNC/utils/websockify/docker /opt/bin/noVNC/utils/websockify/tests \
#========================================================================
# Run this command for executable file permissions for /dev/shm when    #
# this is a "child" container running in Docker Desktop and WSL2 distro #
#========================================================================
  && chmod +x /dev/shm \
# Creating base directory for Xvfb
  && mkdir -p /tmp/.X11-unix \
#==============================
# Generating the VNC password using initial password in Base image
# Changing ownership to ${SEL_USER}, so the service can be started
#==============================
  && x11vnc -storepasswd $(cat /run/secrets/SEL_PASSWD) ${HOME}/.vnc/passwd \
  && chown -R "${SEL_USER}:${SEL_GROUP}" ${HOME}/.vnc \
  && chmod -R 775 ${HOME} /tmp/.X11-unix \
  && chgrp -R 0 ${HOME} /tmp/.X11-unix \
  && chmod -R g=u ${HOME} /tmp/.X11-unix

# Copying configuration script generator
COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-node.sh \
      start-xvfb.sh \
      start-vnc.sh \
      start-novnc.sh \
      generate_config generate_relay_config /opt/bin/

# Selenium Grid logo as wallpaper for Fluxbox
COPY selenium_grid_logo.png /usr/share/images/fluxbox/ubuntu-light.png

# Supervisor configuration file
COPY selenium.conf /etc/supervisor/conf.d/

#====================================================
# Run the following commands as non-privileged user #
#====================================================
USER ${SEL_UID}

EXPOSE 5900
