FROM ubuntu:jammy-20231004
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

# Arguments to define the version of dependencies to download
ARG VERSION
ARG RELEASE=selenium-${VERSION}
ARG OPENTELEMETRY_VERSION=1.31.0
ARG GRPC_VERSION=1.59.0

#Arguments to define the user running Selenium
ARG SEL_USER=seluser
ARG SEL_PASSWD=secret
ARG SEL_UID=1200
ARG SEL_GID=1201

USER root
#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu jammy main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu jammy-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
  && apt-get upgrade -yq \
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
    libnss3-tools \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-11-openjdk-amd64/conf/security/java.security

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
ENV SEL_UID=${SEL_UID}
ENV SEL_GID=${SEL_GID}
ENV HOME=/home/${SEL_USER}
ENV SEL_DIR=/opt/selenium
ENV EXTERNAL_JARS=/external_jars
ENV SE_DOWNLOAD_DIR=${HOME}/Downloads

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

#========================================
# Add normal user and group with passwordless sudo
#========================================
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su \
    && sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers \
    && sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers \
    && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN groupadd ${SEL_USER} \
        --gid ${SEL_GID} \
    && useradd ${SEL_USER} \
        --no-log-init \
        --create-home \
        --gid ${SEL_GID} \
        --shell /bin/bash \
        --uid ${SEL_UID} \
    && chmod g+w /etc/passwd \
    && echo "${SEL_USER}:${SEL_PASSWD}" | chpasswd

#======================================
# Create directories needed
#======================================
RUN mkdir -p ${HOME}/.mozilla ${HOME}/.cache \
      ${SEL_DIR} ${SEL_DIR}/assets \
      /var/run/supervisor /var/log/supervisor \
      ${EXTERNAL_JARS} \
      ${SE_DOWNLOAD_DIR}

#======================================
# Add Grid check script
#======================================
COPY --chown="${SEL_UID}:${SEL_GID}" check-grid.sh entry_point.sh /opt/bin/

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#==========
# Selenium
#==========
RUN touch ${SEL_DIR}/config.toml \
  && wget --no-verbose https://github.com/SeleniumHQ/selenium/releases/download/${RELEASE}/selenium-server-${VERSION}.jar \
    -O ${SEL_DIR}/selenium-server.jar

#=====
# Download observability related jaegar jars and make them available in a separate directory
# so that the container can skip downloading them everytime it comes up
#=====
RUN curl -fLo /tmp/cs https://github.com/coursier/launchers/raw/master/coursier \
  && chmod +x /tmp/cs

RUN /tmp/cs fetch --classpath --cache ${EXTERNAL_JARS} \
    io.opentelemetry:opentelemetry-exporter-otlp:${OPENTELEMETRY_VERSION} \
    io.opentelemetry:opentelemetry-exporter-jaeger:${OPENTELEMETRY_VERSION} \
    io.grpc:grpc-netty:${GRPC_VERSION} > ${EXTERNAL_JARS}/.classpath.txt
RUN rm -fr /root/.cache/*

# Change ownership of directories
RUN chown -R "${SEL_USER}:${SEL_GID}" ${HOME} ${SEL_DIR} ${SEL_DIR}/assets ${EXTERNAL_JARS} ${SE_DOWNLOAD_DIR} /var/run/supervisor /var/log/supervisor \
    && fix-permissions ${HOME} ${SEL_DIR} ${SEL_DIR}/assets ${EXTERNAL_JARS} ${SE_DOWNLOAD_DIR} /var/run/supervisor /var/log/supervisor

#==========
# Relaxing permissions for OpenShift and other non-sudo environments
#==========
RUN chmod g=u /etc/passwd

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER ${SEL_UID}:${SEL_GID}

# Boolean value, maps "--bind-host"
ENV SE_BIND_HOST false

CMD ["/opt/bin/entry_point.sh"]
