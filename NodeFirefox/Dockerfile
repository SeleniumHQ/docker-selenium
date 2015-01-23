FROM selenium/node-base:2.44.0
MAINTAINER Selenium <selenium-developers@googlegroups.com>

USER root

#=========
# Firefox
#=========
ENV FIREFOX_VERSION 28.0+build2-0ubuntu2
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    firefox=$FIREFOX_VERSION \
  && rm -rf /var/lib/apt/lists/*

#========================
# Selenium Configuration
#========================
COPY config.json /opt/selenium/config.json

USER seluser
