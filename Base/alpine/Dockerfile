FROM alpine:edge
MAINTAINER Selenium <selenium-developers@googlegroups.com>

RUN apk add --no-cache \
        bash \
        wget \
        unzip \
        ca-certificates \
        openjdk8-jre \
        sudo \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' /usr/lib/jvm/java-1.8-openjdk/jre/lib/security/java.security \
    && mkdir -p /opt/selenium \
    && wget --no-verbose https://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar -O /opt/selenium/selenium-server-standalone.jar \
    && addgroup sudo \
    && adduser seluser -s /bin/bash -G sudo -D \
    && echo 'seluser:secret' | chpasswd \
    && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
