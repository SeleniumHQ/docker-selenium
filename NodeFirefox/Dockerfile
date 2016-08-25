FROM selenium/node-base:2.53.1
MAINTAINER Selenium <selenium-developers@googlegroups.com>

USER root

#=========
# Firefox
#=========
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install firefox \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get -y purge firefox
ENV FIREFOX_VERSION 47.0.1
RUN for VERSION in 47.0.1 46.0.1 45.0.2; do \
    wget --no-verbose -O /tmp/firefox-$VERSION.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$VERSION/linux-x86_64/en-US/firefox-$VERSION.tar.bz2 \
    && mkdir -p /opt/firefox/$VERSION \
    && tar -C /opt/firefox/$VERSION --strip-components 1 -xjf /tmp/firefox-$VERSION.tar.bz2 \
    && rm /tmp/firefox-$VERSION.tar.bz2 \
  ;done
RUN ln -fs /opt/firefox/$FIREFOX_VERSION/firefox /usr/bin/firefox

#========================
# Selenium Configuration
#========================
COPY config.json /opt/selenium/config.json

USER seluser
