FROM ubuntu:noble@sha256:186072bba1b2f436cbb91ef2567abca677337cfc786c86e107d25b7072feef0c
ARG AUTHORS=SeleniumHQ
LABEL authors="${AUTHORS} <docker-selenium@seleniumhq.org>"
LABEL org.opencontainers.image.source="https://github.com/${AUTHORS}/docker-selenium"

# Arguments to define the version of dependencies to download
ARG VERSION
ARG RELEASE=selenium-${VERSION}
# Default value should be aligned with upstream Selenium (https://github.com/SeleniumHQ/selenium/blob/trunk/MODULE.bazel)
ARG OPENTELEMETRY_VERSION=latest.release
ARG GRPC_VERSION=latest.release
ARG NETTY_VERSION=latest.release
ARG CS_VERSION=2.1.25-M23
ARG ENVSUBST_VERSION=1.5.0
ARG CURL_VERSION=8.18.0
ARG PYTHON_VERSION=3.14

#Arguments to define the user running Selenium
ARG SEL_USER=seluser
ARG SEL_GROUP=${SEL_USER}
ARG HOME=/home/${SEL_USER}
ARG UID=1200
ARG GID=1201
ARG TZ="UTC"
ARG JRE_VERSION=21
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
    SEL_DOWNLOAD_DIR=${HOME}/Downloads \
    VIDEO_FOLDER="/videos" \
    # Path to the Configfile
    CONFIG_FILE="/opt/selenium/config.toml" \
    VENV_PATH=${HOME}/venv

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
#RUN echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n" > /etc/apt/sources.list \
#    && echo "deb-src [arch=amd64] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse\n" >> /etc/apt/sources.list \
#    && echo "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble main restricted universe multiverse" >> /etc/apt/sources.list \
#    && echo "deb-src [arch=arm64] http://ports.ubuntu.com/ubuntu-ports noble main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get -qqy update \
  && apt-get upgrade -yq \
  && apt-get -qqy --no-install-recommends install \
    acl \
    bzip2 \
    xz-utils \
    tzdata \
    sudo \
    unzip \
    wget \
    jq \
    gnupg2 \
    libnss3-tools \
    openjdk-${JRE_VERSION}-jdk-headless \
    ca-certificates \
    xterm \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#========================================
# Add normal user and group without password sudo
#========================================
RUN --mount=type=secret,id=SEL_PASSWD \
  groupadd ${SEL_GROUP} \
         --gid ${SEL_GID} \
  && useradd ${SEL_USER} \
         --create-home \
         --gid ${SEL_GID} \
         --shell /bin/bash \
         --uid ${SEL_UID} \
  && usermod -a -G sudo ${SEL_USER} \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo "${SEL_USER}:$(cat /run/secrets/SEL_PASSWD)" | chpasswd

#========================================
# Install Python for utilities
#========================================
ENV PATH="$VENV_PATH/bin:$PATH" \
    VIRTUAL_ENV="$VENV_PATH"

RUN gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys F23C5A6CF475977595C89F51BA6932366A755776 \
    && gpg --export F23C5A6CF475977595C89F51BA6932366A755776 > /usr/share/keyrings/deadsnakes.pgp \
    && echo "deb [signed-by=/usr/share/keyrings/deadsnakes.pgp] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble main" | tee /etc/apt/sources.list.d/deadsnakes.list \
    && apt-get -qqy update \
    && apt-get upgrade -yq \
    && apt-get -qqy --no-install-recommends install python${PYTHON_VERSION} python${PYTHON_VERSION}-venv \
    && dpkg-divert --add --rename --divert /usr/bin/python3.distrib /usr/bin/python3 \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN ARCH=$(if [ "$(dpkg --print-architecture)" = "arm64" ]; then echo "aarch64"; else echo "$(dpkg --print-architecture)"; fi) \
    && wget -q https://github.com/NDViet/static-curl/releases/download/${CURL_VERSION}/curl-$ARCH -O /usr/bin/curl \
    && chmod +x /usr/bin/curl \
    && curl --version

RUN if [ "${TARGETARCH}" = "arm" ] && [ "${TARGETVARIANT}" = "v7" ]; then \
       export ARCH=armhf ; \
    else \
       export ARCH=$(dpkg --print-architecture) ; \
    fi \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' /usr/lib/jvm/java-${JRE_VERSION}-openjdk-${ARCH}/conf/security/java.security \
#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
  && ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    cat /etc/timezone \
#==========
# Selenium & relaxing permissions for OpenShift and other non-sudo environments
#==========
  && mkdir -p /opt/selenium /opt/selenium/assets /opt/selenium/secrets /opt/selenium/logs /var/run/supervisor /var/log/supervisor ${SEL_DOWNLOAD_DIR} \
    ${HOME}/.mozilla ${HOME}/.vnc ${HOME}/.pki/nssdb ${VIDEO_FOLDER} \
  # NSSDB initialization with an empty password
  && certutil -d sql:${HOME}/.pki/nssdb -N --empty-password \
  && touch ${CONFIG_FILE} \
  && chown -R ${SEL_USER}:${SEL_GROUP} /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} ${VIDEO_FOLDER} \
  && chmod -R 775 /opt/selenium /var/run/supervisor /var/log/supervisor /etc/passwd ${HOME} ${VIDEO_FOLDER} \
  && wget --no-verbose https://github.com/${AUTHORS}/selenium/releases/download/${RELEASE}/selenium-server-${VERSION}.jar \
    -O /opt/selenium/selenium-server.jar \
  && chgrp -R 0 /opt/selenium ${HOME} ${VIDEO_FOLDER} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && chmod -R g=u /opt/selenium ${HOME} ${VIDEO_FOLDER} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm u:${SEL_USER}:rwx /opt /opt/selenium ${HOME} ${VIDEO_FOLDER} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
  && setfacl -Rm g:${SEL_GROUP}:rwx /opt /opt/selenium ${HOME} ${VIDEO_FOLDER} /opt/selenium/assets /var/run/supervisor /var/log/supervisor \
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
        io.grpc:grpc-netty:${GRPC_VERSION} \
        io.netty:netty-handler-proxy:${NETTY_VERSION} \
        io.netty:netty-parent:${NETTY_VERSION} \
        io.netty:netty-codec-http:${NETTY_VERSION} \
        io.netty:netty-codec-http2:${NETTY_VERSION} \
        io.netty:netty-codec:${NETTY_VERSION} \
        > /external_jars/.classpath.txt \
        && chmod 664 /external_jars/.classpath.txt ; \
     fi \
  && rm -fr /root/.cache/* \
  # (Note that .bashrc is only executed in interactive bash shells.)
  && echo 'if [[ $(ulimit -n) -gt 200000 ]]; then echo "WARNING: Very high value reported by \"ulimit -n\". Consider passing \"--ulimit nofile=32768\" to \"docker run\"."; fi' >> ${HOME}/.bashrc

#======================================
# Add Grid check script
#======================================
COPY --chown="${SEL_UID}:${SEL_GID}" check-grid.sh entry_point.sh configs/node/nodeGridUrl.sh configs/node/nodePreStop.sh handle_heap_dump.sh /opt/bin/
COPY --chown="${SEL_UID}:${SEL_GID}" mask /usr/local/bin/
RUN chmod +x /opt/bin/*.sh /usr/local/bin/mask

#======================================
# Add Supervisor configuration file
#======================================
COPY supervisord.conf /etc

#===================================================
# Add the default self-signed certificate to the bundle CA
#===================================================
#ARG CERT_TRUST_ATTR=TCu,Cu,Tu
COPY --chown="${SEL_UID}:${SEL_GID}" certs/add-cert-helper.sh certs/add-jks-helper.sh /opt/bin/
#COPY --chown="${SEL_UID}:${SEL_GID}" certs/tls.crt certs/tls.key certs/server.jks certs/server.pass /opt/selenium/secrets/

#===================================================
# Add envsubst binary
#===================================================
RUN ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "x86_64"; else echo "$(dpkg --print-architecture)"; fi) \
    && curl -fsSL https://github.com/ndviet/envsubst/releases/download/v${ENVSUBST_VERSION}/envsubst-$(uname -s)-${ARCH} -o envsubst \
    && chmod +x envsubst \
    && mv envsubst /usr/local/bin \
    && ln -sf /usr/local/bin/envsubst /usr/bin/envsubst

#===================================================
# Run the following commands as non-privileged user
#===================================================
USER ${SEL_UID}:${SEL_GID}

RUN python3 -m venv $VENV_PATH \
    && $VENV_PATH/bin/python3 -m pip install --upgrade pip psutil requests pyzmq \
    && wget -q https://github.com/Supervisor/supervisor/archive/refs/heads/main.zip -O /tmp/supervisor.zip \
    && unzip /tmp/supervisor.zip -d /tmp \
    && cd /tmp/supervisor-main \
    && $VENV_PATH/bin/python3 -m pip install . \
    && rm -rf /tmp/supervisor.zip /tmp/supervisor-main \
    && python3 --version \
    && echo "source $VENV_PATH/bin/activate" >> ${HOME}/.bashrc

#RUN /opt/bin/add-jks-helper.sh -d /opt/selenium/secrets \
#    && /opt/bin/add-cert-helper.sh -d /opt/selenium/secrets ${CERT_TRUST_ATTR}
#======================================
# Configure environement
#======================================
    # Boolean value, maps "--bind-host"
ENV SE_BIND_HOST="false" \
    SE_SERVER_PROTOCOL="http" \
    # Boolean value, maps "--reject-unsupported-caps"
    SE_REJECT_UNSUPPORTED_CAPS="false" \
    SE_DISTRIBUTOR_SLOT_SELECTOR="" \
    SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED="true" \
    SE_OTEL_TRACES_EXPORTER="otlp" \
    SE_SUPERVISORD_LOG_LEVEL="info" \
    SE_SUPERVISORD_CHILD_LOG_DIR="/tmp" \
    SE_SUPERVISORD_LOG_FILE="/tmp/supervisord.log" \
    SE_SUPERVISORD_PID_FILE="/tmp/supervisord.pid" \
    SE_SUPERVISORD_AUTO_RESTART="true" \
    SE_SUPERVISORD_START_RETRIES="5" \
    SE_SUPERVISORD_UNIX_SERVER_PASSWORD="secret" \
    SE_LOG_TIMESTAMP_FORMAT="%Y-%m-%d %H:%M:%S,%3N" \
    SE_LOG_LEVEL="INFO" \
    SE_HTTP_LOGS="false" \
    SE_STRUCTURED_LOGS="false" \
    SE_PLAIN_LOGS="true" \
    SE_ENABLE_TRACING="true" \
    SE_ENABLE_TLS="false" \
    SE_JAVA_OPTS_DEFAULT="" \
    SE_JAVA_HEAP_DUMP="false" \
    SE_JAVA_HTTPCLIENT_VERSION="HTTP_1_1" \
    SE_JAVA_SSL_TRUST_STORE="/opt/selenium/secrets/server.jks" \
    SE_JAVA_SSL_TRUST_STORE_PASSWORD="/opt/selenium/secrets/server.pass" \
    SE_JAVA_DISABLE_HOSTNAME_VERIFICATION="true" \
    SE_HTTPS_CERTIFICATE="/opt/selenium/secrets/tls.crt" \
    SE_HTTPS_PRIVATE_KEY="/opt/selenium/secrets/tls.key"

CMD ["/opt/bin/entry_point.sh"]
