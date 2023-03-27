# FROM ubuntu:focal-20210416
#FROM ubuntu:focal-20210827
#FROM ubuntu:focal-20211006
#FROM ubuntu:focal-20220302
#FROM ubuntu:focal-20220415
#FROM ubuntu:focal-20220531
#FROM ubuntu:focal-20230301
FROM debian:latest
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

#================================================
# Customize sources for apt-get
#================================================
#RUN  echo "deb http://archive.ubuntu.com/ubuntu focal main universe\n" > /etc/apt/sources.list \
#  && echo "deb http://archive.ubuntu.com/ubuntu focal-updates main universe\n" >> /etc/apt/sources.list \
#  && echo "deb http://security.ubuntu.com/ubuntu focal-security main universe\n" >> /etc/apt/sources.list

ARG TARGETARCH
ARG TARGETVARIANT

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true


#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    acl \
    bzip2 \
    ca-certificates \
    openjdk-11-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    curl \
    supervisor \
    gnupg2 \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* 

#===================

RUN if [ $TARGETARCH = "arm" ] && [ $TARGETVARIANT = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$TARGETARCH ; \
    fi \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-11-openjdk-$ARCH/conf/security/java.security


#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#========================================
# Add normal user and group with passwordless sudo
#========================================
RUN groupadd seluser \
         --gid 1201 \
  && useradd seluser \
         --create-home \
         --gid 1201 \
         --shell /bin/bash \
         --uid 1200 \
  && usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'seluser:secret' | chpasswd
ENV HOME=/home/seluser

#======================================
# Add Grid check script
#======================================
COPY check-grid.sh entry_point.sh /opt/bin/

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN  mkdir -p /opt/selenium /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && touch /opt/selenium/config.toml \
  && chmod -R 777 /opt/selenium /opt/selenium/assets /var/run/supervisor /var/log/supervisor /etc/passwd \
  && wget --no-verbose https://github.com/SeleniumHQ/selenium/releases/download/selenium-4.8.0/selenium-server-4.8.2.jar \
    -O /opt/selenium/selenium-server.jar \
  && wget --no-verbose https://repo1.maven.org/maven2/org/seleniumhq/selenium/selenium-http-jdk-client/4.8.2/selenium-http-jdk-client-4.8.2.jar \
    -O /opt/selenium/selenium-http-jdk-client.jar \
  && chgrp -R 0 /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm u:seluser:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor

#=====
# Download observability related jaegar jars and make them available in a separate directory
# so that the container can skip downloading them everytime it comes up
#=====
#RUN curl -fLo /tmp/cs https://github.com/coursier/launchers/raw/master/coursier \
# RUN if [ `arch` = "aarch64" ] || [ `arch` = "x86_64" ]; then \
RUN if [ `arch` = "aarch64" ]; then \
    curl -fL https://github.com/coursier/launchers/raw/master/cs-`arch`-pc-linux.gz | gzip -d > /tmp/cs \
  && chmod +x /tmp/cs \
  && mkdir -p /external_jars \
  && chmod -R 775 /external_jars ; \
    fi

RUN if [ -f "/tmp/cs" ]; then \
    /tmp/cs fetch --classpath --cache /external_jars io.opentelemetry:opentelemetry-exporter-jaeger:1.22.0 io.grpc:grpc-netty:1.52.1 > /external_jars/.classpath.txt ; \
    fi

RUN if [ -f "/tmp/cs" ]; then chmod 664 /external_jars/.classpath.txt ; fi

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER 1200:1201

# Boolean value, maps "--bind-host"
ENV SE_BIND_HOST false

CMD ["/opt/bin/entry_point.sh"]
