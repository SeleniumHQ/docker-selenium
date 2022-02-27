# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM seleniarm/node-base:4.1.2-20220227
LABEL authors=SeleniumHQ,sj26,jamesmortensen

#FROM local-seleniarm/node-base:4.0.0-20211018
#LABEL authors=SeleniumHQ,sj26,jamesmortensen

ARG TARGETARCH
ARG TARGETVARIANT

USER root

#=========
# Firefox
#=========
RUN echo "deb http://ftp.hk.debian.org/debian/ sid main" >> /etc/apt/sources.list \
  && apt-get update -qqy \
  # && apt-get -qqy install firefox-esr libavcodec-extra \
  && apt-get -qqy install firefox libavcodec-extra \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# geckodriver-arm64 was built using the local-seleniarm/geckodriver-arm64 Debian image
COPY geckodriver /opt/geckodriver-bin/geckodriver-arm64

RUN if [ $TARGETARCH = "arm" ] && [ $TARGETVARIANT = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$TARGETARCH ; \
    fi ; \
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "armhf" ]; then \
       echo "Symlinking pre-built ARM geckodriver to /usr/local/bin/geckodriver" ; \
       ln -s /opt/geckodriver-bin/geckodriver-arm64 /usr/local/bin/geckodriver ; \
       chmod 755 /usr/local/bin/geckodriver ; \
    else \
       wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.30.0/geckodriver-v0.30.0-linux64.tar.gz ; \
       tar -C /tmp -zxf /tmp/geckodriver.tar.gz ; \
       rm /tmp/geckodriver.tar.gz ; \
       mv /tmp/geckodriver /opt/geckodriver-bin/geckodriver-amd64 ; \
       echo "Symlinking AMD64 geckodriver to /usr/local/bin/geckodriver" ; \
       ln -s /opt/geckodriver-bin/geckodriver-amd64 /usr/local/bin/geckodriver ; \
       chmod 755 /usr/local/bin/geckodriver ; \
    fi

USER 1200

#============================================
# Dumping Browser name and version for config
#============================================
RUN echo "firefox" > /opt/selenium/browser_name