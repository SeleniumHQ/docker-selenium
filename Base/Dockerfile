FROM debian:bookworm
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

# Arguments to define the version of dependencies to download
ARG VERSION
ARG RELEASE=selenium-${VERSION}
ARG AUTHORS=SeleniumHQ
# Default value should be aligned with upstream Selenium (https://github.com/SeleniumHQ/selenium/blob/trunk/java/maven_deps.bzl)
ARG OPENTELEMETRY_VERSION=1.36.0
ARG GRPC_VERSION=1.62.2

#Arguments to define the user running Selenium
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG SEL_PASSWD=secret
ARG UID=1200
ARG GID=1201
ARG TZ="UTC"
ARG JRE_VERSION=17
ARG TARGETARCH=amd64
ARG TARGETVARIANT

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    # No interactive frontend during docker build
    DEBCONF_NONINTERACTIVE_SEEN=true \
    SEL_USER=${SEL_USER} \
    SEL_UID=${UID} \
    SEL_GID=${GID} \
    HOME=/home/${SEL_USER} \
    TZ=${TZ} \
    SEL_DOWNLOAD_DIR=${HOME}/Downloads

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN  echo "deb http://archive.ubuntu.com/ubuntu jammy main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu jammy-updates main universe\n" >> /etc/apt/sources.list \
  && echo "deb http://security.ubuntu.com/ubuntu jammy-security main universe\n" >> /etc/apt/sources.list \
  && apt-get -qqy update \
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
  && apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv-keys 843C48A565F8F04B || apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 843C48A565F8F04B \
  && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc >dev/null \
  && echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list >dev/null \
  && apt-get -qqy update \
  && apt-get -qqy --no-install-recommends install temurin-${JRE_VERSION}-jre -y \
  && if [ "${TARGETARCH}" = "arm" ] && [ "${TARGETVARIANT}" = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=${TARGETARCH} ; \
    fi \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/temurin-${JRE_VERSION}-jre-${ARCH}/conf/security/java.security \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
  && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    cat /etc/timezone \
#========================================
# Add normal user and group without password sudo
#========================================
  && groupadd ${SEL_GROUP} \
         --gid ${SEL_GID} \
  && useradd ${SEL_USER} \
         --create-home \
         --gid ${SEL_GID} \
         --shell /bin/bash \
         --uid ${SEL_UID} \
  && usermod -a -G sudo ${SEL_USER} \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo "${SEL_USER}:${SEL_PASSWD}" | chpasswd \
#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
  && mkdir -p /opt/selenium /opt/selenium/assets /var/run/supervisor /var/log/supervisor ${SEL_DOWNLOAD_DIR} \
    ${HOME}/.mozilla ${HOME}/.vnc $HOME/.pki/nssdb \
  # NSSDB initialization with an empty password
  && certutil -d sql:$HOME/.pki/nssdb -N --empty-password \
  && touch /opt/selenium/config.toml \
  && chown -R ${SEL_USER}:${SEL_GROUP} /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && chmod -R 775 /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && wget --no-verbose https://github.com/${AUTHORS}/selenium/releases/download/${RELEASE}/selenium-server-${VERSION}.jar \
    -O /opt/selenium/selenium-server.jar \
  && echo "${SEL_PASSWD}" > /opt/selenium/initialPasswd \
  && chgrp -R 0 /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm u:${SEL_USER}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm g:${SEL_GROUP}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
#=====
# Download observability related OpenTelemetry jars and make them available in a separate directory
# so that the container can skip downloading them everytime it comes up
#=====
  && curl -fLo /tmp/cs https://github.com/coursier/launchers/raw/master/coursier \
  && chmod +x /tmp/cs \
  && mkdir -p /external_jars \
  && chmod -R 775 /external_jars \
  && /tmp/cs fetch --classpath --cache /external_jars \
    io.opentelemetry:opentelemetry-exporter-otlp:${OPENTELEMETRY_VERSION} \
    io.grpc:grpc-netty:${GRPC_VERSION} > /external_jars/.classpath.txt \
  && chmod 664 /external_jars/.classpath.txt \
  && rm -fr /root/.cache/* \
  # (Note that .bashrc is only executed in interactive bash shells.)
  && echo 'if [[ $(ulimit -n) -gt 200000 ]]; then echo "WARNING: Very high value reported by \"ulimit -n\". Consider passing \"--ulimit nofile=32768\" to \"docker run\"."; fi' >> ${HOME}/.bashrc

#======================================
# Add Grid check script
#======================================
COPY --chown="${SEL_UID}:${SEL_GID}" check-grid.sh entry_point.sh /opt/bin/

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER ${SEL_UID}:${SEL_GID}

#======================================
# Configure environement
#======================================
    # Boolean value, maps "--bind-host"
ENV SE_BIND_HOST=false \
    # Boolean value, maps "--reject-unsupported-caps"
    SE_REJECT_UNSUPPORTED_CAPS=false \
    SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED=true \
    SE_OTEL_TRACES_EXPORTER="otlp"

CMD ["/opt/bin/entry_point.sh"]
