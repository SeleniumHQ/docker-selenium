FROM ubuntu:noble-20240801
LABEL authors="Selenium <selenium-developers@googlegroups.com>"

# Arguments to define the version of dependencies to download
ARG VERSION
ARG RELEASE=selenium-${VERSION}
ARG AUTHORS=SeleniumHQ
# Default value should be aligned with upstream Selenium (https://github.com/SeleniumHQ/selenium/blob/trunk/MODULE.bazel)
ARG OPENTELEMETRY_VERSION=1.40.0
ARG GRPC_VERSION=1.65.1
ARG NETTY_VERSION=4.1.111.Final
ARG CS_VERSION=2.1.10

#Arguments to define the user running Selenium
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG HOME=/home/${SEL_USER}
ARG UID=1200
ARG GID=1201
ARG TZ="UTC"
ARG JRE_VERSION=17
ARG TARGETARCH
ARG TARGETVARIANT

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    # No interactive frontend during docker build
    DEBCONF_NONINTERACTIVE_SEEN=true \
    SEL_USER=${SEL_USER} \
    SEL_UID=${UID} \
    SEL_GID=${GID} \
    HOME=${HOME} \
    TZ=${TZ} \
    SEL_DOWNLOAD_DIR=${HOME}/Downloads

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN --mount=type=secret,id=SEL_PASSWD \
  if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
      echo "deb http://archive.ubuntu.com/ubuntu noble main universe\n" > /etc/apt/sources.list \
      && echo "deb http://archive.ubuntu.com/ubuntu noble-updates main universe\n" >> /etc/apt/sources.list \
      && echo "deb http://security.ubuntu.com/ubuntu noble-security main universe\n" >> /etc/apt/sources.list ; \
     fi \
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
    openjdk-${JRE_VERSION}-jre-headless \
  && if [ "${TARGETARCH}" = "arm" ] && [ "${TARGETVARIANT}" = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$(dpkg --print-architecture) ; \
    fi \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' /usr/lib/jvm/java-${JRE_VERSION}-openjdk-${ARCH}/conf/security/java.security \
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
  && echo "${SEL_USER}:$(cat /run/secrets/SEL_PASSWD)" | chpasswd \
#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
  && mkdir -p /opt/selenium /opt/selenium/assets /opt/selenium/secrets /var/run/supervisor /var/log/supervisor ${SEL_DOWNLOAD_DIR} \
    ${HOME}/.mozilla ${HOME}/.vnc ${HOME}/.pki/nssdb \
  # NSSDB initialization with an empty password
  && certutil -d sql:${HOME}/.pki/nssdb -N --empty-password \
  && touch /opt/selenium/config.toml \
  && chown -R ${SEL_USER}:${SEL_GROUP} /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && chmod -R 775 /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} \
  && wget --no-verbose https://github.com/${AUTHORS}/selenium/releases/download/${RELEASE}/selenium-server-${VERSION}.jar \
    -O /opt/selenium/selenium-server.jar \
  && chgrp -R 0 /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm u:${SEL_USER}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm g:${SEL_GROUP}:rwx /opt /opt/selenium ${HOME} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
#=====
# Download observability related OpenTelemetry jars and make them available in a separate directory
# so that the container can skip downloading them everytime it comes up
#===== \
  && if [ `arch` = "aarch64" ] || [ `arch` = "x86_64" ]; then \
        curl -fL https://github.com/coursier/coursier/releases/download/v${CS_VERSION}/coursier.jar > /tmp/cs \
        && chmod +x /tmp/cs \
        && mkdir -p /external_jars \
        && chmod -R 775 /external_jars ; \
     fi \
  && if [ -f "/tmp/cs" ]; then \
        java -jar /tmp/cs fetch --classpath --cache /external_jars \
        io.opentelemetry:opentelemetry-exporter-otlp:${OPENTELEMETRY_VERSION} \
        io.grpc:grpc-netty:${GRPC_VERSION} io.netty:netty-codec-http:${NETTY_VERSION} > /external_jars/.classpath.txt \
        && chmod 664 /external_jars/.classpath.txt ; \
     fi \
  && rm -fr /root/.cache/* \
  # (Note that .bashrc is only executed in interactive bash shells.)
  && echo 'if [[ $(ulimit -n) -gt 200000 ]]; then echo "WARNING: Very high value reported by \"ulimit -n\". Consider passing \"--ulimit nofile=32768\" to \"docker run\"."; fi' >> ${HOME}/.bashrc

#======================================
# Add Grid check script
#======================================
COPY --chown="${SEL_UID}:${SEL_GID}" check-grid.sh entry_point.sh configs/node/nodeGridUrl.sh configs/node/nodePreStop.sh /opt/bin/
COPY --chown="${SEL_UID}:${SEL_GID}" mask /usr/local/bin/

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#===================================================
# Add the default self-signed certificate to the bundle CA
#===================================================
ARG CERT_TRUST_ATTR=TCu,Cu,Tu
COPY --chown="${SEL_UID}:${SEL_GID}" certs/add-cert-helper.sh certs/add-jks-helper.sh /opt/bin/
COPY --chown="${SEL_UID}:${SEL_GID}" certs/tls.crt certs/tls.key certs/server.jks certs/server.pass /opt/selenium/secrets/

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER ${SEL_UID}:${SEL_GID}

RUN /opt/bin/add-jks-helper.sh -d /opt/selenium/secrets \
    && /opt/bin/add-cert-helper.sh -d /opt/selenium/secrets ${CERT_TRUST_ATTR}
#======================================
# Configure environement
#======================================
    # Boolean value, maps "--bind-host"
ENV SE_BIND_HOST=false \
    SE_SERVER_PROTOCOL="http" \
    # Boolean value, maps "--reject-unsupported-caps"
    SE_REJECT_UNSUPPORTED_CAPS=false \
    SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED=true \
    SE_OTEL_TRACES_EXPORTER="otlp" \
    SE_SUPERVISORD_LOG_LEVEL="info" \
    SE_SUPERVISORD_CHILD_LOG_DIR="/tmp" \
    SE_SUPERVISORD_LOG_FILE="/tmp/supervisord.log" \
    SE_SUPERVISORD_PID_FILE="/tmp/supervisord.pid" \
    SE_LOG_LEVEL="INFO" \
    SE_HTTP_LOGS=false \
    SE_STRUCTURED_LOGS=false \
    SE_ENABLE_TRACING=true \
    SE_ENABLE_TLS=false \
    SE_JAVA_SSL_TRUST_STORE="/opt/selenium/secrets/server.jks" \
    SE_JAVA_SSL_TRUST_STORE_PASSWORD="/opt/selenium/secrets/server.pass" \
    SE_JAVA_DISABLE_HOSTNAME_VERIFICATION=true \
    SE_HTTPS_CERTIFICATE="/opt/selenium/secrets/tls.crt" \
    SE_HTTPS_PRIVATE_KEY="/opt/selenium/secrets/tls.key"

CMD ["/opt/bin/entry_point.sh"]
