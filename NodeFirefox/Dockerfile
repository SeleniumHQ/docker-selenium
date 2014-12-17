FROM selenium/node-base:2.44.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>

USER root

#=========
# Firefox
#=========
RUN apt-get update -qqy && \
      apt-get -qqy --no-install-recommends install firefox && \
      rm -rf /var/lib/apt/lists/*

#============
# FlashPlayer
#============
RUN sed -i 's/main universe$/main multiverse/' /etc/apt/sources.list && \
      apt-get update -qqy && \
      apt-get -qqy --no-install-recommends install \
        software-properties-common && \
      add-apt-repository -y ppa:nilarimogard/webupd8 && \
      apt-get update -qqy && \
      apt-get -qqy --no-install-recommends install \
        freshplayerplugin pepperflashplugin-nonfree

#========================
# Selenium Configuration
#========================
COPY config.json /opt/selenium/config.json

USER seluser
