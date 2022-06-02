# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM seleniarm/node-base:4.1.4-20220429
LABEL authors=SeleniumHQ

ARG TARGETARCH
ARG TARGETVARIANT

ARG GECKODRIVER_VERSION=0.31.0

USER root

#=========
# Firefox
#=========
#RUN echo "deb http://deb.debian.org/debian/ sid main" >> /etc/apt/sources.list \
  # && apt-get update -qqy \
  # && apt-get -qqy install firefox-esr libavcodec-extra \
  # && apt-get -qqy install firefox libavcodec-extra \
  # && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Pulling Firefox from Debian Snapshots so we can control which version we use as latest
RUN echo "deb http://deb.debian.org/debian/ sid main" >> /etc/apt/sources.list \
  && apt-get update -qqy \
  && apt-get install libavcodec-extra -y \
  && wget https://snapshot.debian.org/archive/debian/20220418T084218Z/pool/main/f/firefox/firefox_99.0-1_`dpkg --print-architecture`.deb -O firefox.deb \
  && apt install ./firefox.deb -y \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* ./firefox.deb

#=============
# geckodriver
#=============
RUN if [ $TARGETARCH = "arm" ] && [ $TARGETVARIANT = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$TARGETARCH ; \
    fi ; \
    if [ -z "$ARCH" ]; then \
       echo "*** BUILD ERROR: \$TARGETARCH must be arm64, amd64, or arm with \$TARGETVARIANT set to v7... exiting..." ; \
       exit 1 ; \
    fi ; \
    if [ "$ARCH" = "arm64" ]; then \ 
       wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/jamesmortensen/geckodriver-arm-binaries/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux-aarch64.tar.gz ; \
    elif [ "$ARCH" = "armhf" ]; then \
       wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/jamesmortensen/geckodriver-arm-binaries/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux-armv7l.tar.gz ; \
    else \
       wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v$GECKODRIVER_VERSION/geckodriver-v$GECKODRIVER_VERSION-linux64.tar.gz ; \
    fi ; \
    tar -C /tmp -zxf /tmp/geckodriver.tar.gz ; \
    rm /tmp/geckodriver.tar.gz ; \
    mkdir -p /opt/geckodriver-bin ; \
    mv /tmp/geckodriver /opt/geckodriver-bin/geckodriver ; \
    echo "Symlinking geckodriver to /usr/local/bin/geckodriver" ; \
    ln -s /opt/geckodriver-bin/geckodriver /usr/local/bin/geckodriver ; \
    chmod 755 /usr/local/bin/geckodriver

USER 1200

#============================================
# Dumping Browser name and version for config
#============================================
RUN echo "firefox" > /opt/selenium/browser_name
