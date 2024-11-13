ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/node-base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

# Install Chromium
ARG CHROMIUM_VERSION="latest"
ARG CHROMIUM_DEB_SITE="http://deb.debian.org/debian"
RUN echo "deb ${CHROMIUM_DEB_SITE}/ stable main" >> /etc/apt/sources.list \
  && wget -qO- https://ftp-master.debian.org/keys/archive-key-12.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/debian-archive-keyring.gpg \
  && wget -qO- https://ftp-master.debian.org/keys/archive-key-12-security.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/debian-archive-security-keyring.gpg \
  && apt-get update -qqy \
  && if [ "${CHROMIUM_VERSION}" = "latest" ]; \
      then apt-get -qqy --no-install-recommends install chromium-common chromium chromium-l10n chromium-driver; \
     else mkdir -p /tmp/chromium \
      && wget -q ${CHROMIUM_DEB_SITE}/pool/main/c/chromium/chromium-common_${CHROMIUM_VERSION}-1_$(dpkg --print-architecture).deb -O /tmp/chromium/chromium-common.deb \
      && wget -q ${CHROMIUM_DEB_SITE}/pool/main/c/chromium/chromium_${CHROMIUM_VERSION}-1_$(dpkg --print-architecture).deb -O /tmp/chromium/chromium.deb \
      && wget -q ${CHROMIUM_DEB_SITE}/pool/main/c/chromium/chromium-l10n_${CHROMIUM_VERSION}-1_all.deb -O /tmp/chromium/chromium-l10n.deb \
      && wget -q ${CHROMIUM_DEB_SITE}/pool/main/c/chromium/chromium-driver_${CHROMIUM_VERSION}-1_$(dpkg --print-architecture).deb -O /tmp/chromium/chromium-driver.deb \
      && apt-get -qqyf install /tmp/chromium/chromium-common.deb /tmp/chromium/chromium.deb /tmp/chromium/chromium-l10n.deb /tmp/chromium/chromium-driver.deb \
      && rm -rf /tmp/chromium; \
    fi \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chromium Launch Script Wrapper
#=================================
COPY wrap_chromium_binary /opt/bin/wrap_chromium_binary
RUN /opt/bin/wrap_chromium_binary

#============================================
# Chromium cleanup script and supervisord file
#============================================
COPY chrome-cleanup.sh /opt/bin/chrome-cleanup.sh
COPY chrome-cleanup.conf /etc/supervisor/conf.d/chrome-cleanup.conf

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name
RUN chromium --version | awk '{print $2}' > /opt/selenium/browser_version
RUN echo "\"goog:chromeOptions\": {\"binary\": \"/usr/bin/chromium\"}" > /opt/selenium/browser_binary_location

ENV SE_OTEL_SERVICE_NAME="selenium-node-chromium"
