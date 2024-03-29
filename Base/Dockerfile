FROM ubuntu:jammy
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

# Arguments to define the version of dependencies to download
ARG VERSION
ARG RELEASE=selenium-${VERSION}
# Default value should be aligned with upstream Selenium (https://github.com/SeleniumHQ/selenium/blob/trunk/java/maven_deps.bzl)
ARG OPENTELEMETRY_VERSION=1.36.0
ARG GRPC_VERSION=1.62.2

#Arguments to define the user running Selenium
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG SEL_PASSWD=secret
ARG UID=1200
ARG GID=1201

USER root
#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu jammy main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu jammy-security main universe\n" >> /etc/apt/sources.list
ARG TARGETARCH=amd64
ARG TARGETVARIANT

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
ARG JRE_VERSION=17
RUN apt-get -qqy update \
  && apt-get upgrade -yq \
  && apt-get -qqy --no-install-recommends install \
    acl \
    bzip2 \
    ca-certificates \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    curl \
    supervisor \
    gnupg2 \
    libnss3-tools \
  && mkdir -p /etc/apt/keyrings \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 843C48A565F8F04B \
  && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc >dev/null \
  && echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list >dev/null \
  && apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install temurin-${JRE_VERSION}-jre -y \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#===================

RUN if [ $TARGETARCH = "arm" ] && [ $TARGETVARIANT = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$TARGETARCH ; \
    fi \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/temurin-${JRE_VERSION}-jre-$ARCH/conf/security/java.security


#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    cat /etc/timezone

#======================================
# Configure environement
#======================================
ENV SEL_USER=${SEL_USER}
ENV SEL_UID=${UID}
ENV SEL_GID=${GID}
ENV HOME=/home/${SEL_USER}
ENV SEL_DOWNLOAD_DIR=${HOME}/Downloads

#========================================
# Add normal user and group with passwordless sudo
#========================================
RUN groupadd ${SEL_GROUP} \
         --gid ${SEL_GID} \
  && useradd ${SEL_USER} \
         --create-home \
         --gid ${SEL_GID} \
         --shell /bin/bash \
         --uid ${SEL_UID} \
  && usermod -a -G sudo ${SEL_USER} \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo "${SEL_USER}:${SEL_PASSWD}" | chpasswd

#======================================
# Add Grid check script
#======================================
COPY --chown="${SEL_UID}:${SEL_GID}" check-grid.sh entry_point.sh /opt/bin/

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN mkdir -p /opt/selenium /opt/selenium/assets /var/run/supervisor /var/log/supervisor ${SEL_DOWNLOAD_DIR} \
    ${HOME}/.mozilla ${HOME}/.vnc $HOME/.pki/nssdb \
  && touch /opt/selenium/config.toml \
  && chown -R ${SEL_USER}:${SEL_GROUP} /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && chmod -R 775 /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && wget --no-verbose https://github.com/SeleniumHQ/selenium/releases/download/${RELEASE}/selenium-server-${VERSION}.jar \
    -O /opt/selenium/selenium-server.jar \
  && echo "${SEL_PASSWD}" > /opt/selenium/initialPasswd \
  && chgrp -R 0 /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm u:${SEL_USER}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm g:${SEL_GROUP}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor

#=====
# Download observability related jaegar jars and make them available in a separate directory
# so that the container can skip downloading them everytime it comes up
#=====
RUN curl -fLo /tmp/cs https://github.com/coursier/launchers/raw/master/coursier \
  && chmod +x /tmp/cs \
  && mkdir -p /external_jars \
  && chmod -R 775 /external_jars

RUN /tmp/cs fetch --classpath --cache /external_jars \
    io.opentelemetry:opentelemetry-exporter-otlp:${OPENTELEMETRY_VERSION} \
    io.grpc:grpc-netty:${GRPC_VERSION} > /external_jars/.classpath.txt

RUN chmod 664 /external_jars/.classpath.txt
RUN rm -fr /root/.cache/*

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER ${SEL_UID}:${SEL_GID}

#==========
# NSSDB initialization with an empty password
#==========
RUN certutil -d sql:$HOME/.pki/nssdb -N --empty-password

# Boolean value, maps "--bind-host"
ENV SE_BIND_HOST false
# Boolean value, maps "--reject-unsupported-caps"
ENV SE_REJECT_UNSUPPORTED_CAPS false

ENV SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED true
ENV SE_OTEL_TRACES_EXPORTER "otlp"

# A too high maximum number of file descriptors (with the default value
# inherited from the docker host) can cause issues with some of our tools:
#  - sanitizers hanging: https://github.com/google/sanitizers/issues/1662
#  - valgrind crashing: https://stackoverflow.com/a/75293014
# This is not be a problem on our CI hosts, but developers who run the image
# on their machines may run into this (e.g., on Arch Linux), so warn them.
# (Note that .bashrc is only executed in interactive bash shells.)
RUN echo 'if [[ $(ulimit -n) -gt 200000 ]]; then echo "WARNING: Very high value reported by \"ulimit -n\". Consider passing \"--ulimit nofile=32768\" to \"docker run\"."; fi' >> ${HOME}/.bashrc

CMD ["/opt/bin/entry_point.sh"]
