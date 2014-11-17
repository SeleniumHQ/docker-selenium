FROM elgalu/selenium-base:2.44.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>

#=================
# Locale settings
#=================
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
RUN locale-gen en_US.UTF-8 \
  && dpkg-reconfigure --frontend noninteractive locales \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    language-pack-en \
  && rm -rf /var/lib/apt/lists/*

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "US/Pacific"
RUN echo "US/Pacific" | sudo tee /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#==============
# VNC and Xvfb
#==============
RUN apt-get update -qqy \
  && apt-get -qqy install \
    x11vnc \
    xvfb \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /home/seluser/.vnc \
  && x11vnc -storepasswd secret /home/seluser/.vnc/passwd \
  && chmod +r /home/seluser/.vnc/passwd

#=======
# Fonts
#=======
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fonts-ipafont-gothic \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-cyrillic \
    xfonts-scalable \
  && rm -rf /var/lib/apt/lists/*

#=========
# fluxbox
# A fast, lightweight and responsive window manager
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    fluxbox \
  && rm -rf /var/lib/apt/lists/*

#===================================================================================
# Scripts to run Xvfb, x11vnc, fluxbox, selenium hub, and selenium node as services
#===================================================================================
COPY ./etc /etc
RUN chmod +x /etc/my_init.d/*.sh \
  && chmod +x /etc/service/**/run

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1360
ENV SCREEN_HEIGHT 1020
ENV SCREEN_DEPTH 24
ENV DISPLAY :20.0

EXPOSE 5900
