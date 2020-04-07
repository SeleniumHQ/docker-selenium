FROM ubuntu:bionic-20200311
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu bionic main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu bionic-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu bionic-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install \
    # bzip2 - high-quality block-sorting file compressor - utilities https://packages.ubuntu.com/bionic/bzip2
    bzip2 \
    # Common CA certificates - https://packages.ubuntu.com/bionic/ca-certificates
    ca-certificates \
    # OpenJDK Java runtime, using Hotspot JIT (headless) - https://packages.ubuntu.com/bionic/openjdk-8-jre-headless
    tzdata \
    # Provide limited super user privileges to specific users - https://packages.ubuntu.com/bionic/sudo
    sudo \
    # De-archiver for .zip files - https://packages.ubuntu.com/bionic/unzip
    unzip \
    # retrieves files from the web - https://packages.ubuntu.com/bionic/wget
    wget \
    # lightweight and flexible command-line JSON processor - https://packages.ubuntu.com/bionic/jq
    jq \
    # command line tool for transferring data with URL syntax - https://packages.ubuntu.com/bionic/curl
    curl \
    # System for controlling process state - https://packages.ubuntu.com/bionic/supervisor
    supervisor \
    # GNU privacy guard - a free PGP replacement (dummy transitional package) - https://packages.ubuntu.com/bionic/gnupg2
    gnupg2 \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
  && dpkg-reconfigure --frontend noninteractive tzdata

#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd seluser \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'seluser:secret' | chpasswd
ENV HOME=/home/seluser

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN  mkdir -p /opt/selenium /var/run/supervisor /var/log/supervisor \
  && touch /opt/selenium/config.json \
  && chmod -R 777 /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd \
  && wget --no-verbose https://selenium-release.storage.googleapis.com/4.0-alpha5/selenium-server-4.0.0-alpha-5.jar \
    -O /opt/selenium/selenium-server.jar \
  && chgrp -R 0 /opt/selenium ${HOME} /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} /var/run/supervisor /var/log/supervisor

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER seluser


CMD ["/opt/bin/entry_point.sh"]
