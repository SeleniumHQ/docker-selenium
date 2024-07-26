ARG NAMESPACE
ARG VERSION
FROM ${NAMESPACE}/node-base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

# Install Chromium
RUN apt-get update -qqy \
  && apt-get install -y software-properties-common \
  && add-apt-repository ppa:xtradeb/apps \
  && apt-get -qqy install chromium chromium-l10n \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chromium Launch Script Wrapper
#=================================
COPY wrap_chromium_binary /opt/bin/wrap_chromium_binary
RUN /opt/bin/wrap_chromium_binary

#============================================
# Chromium webdriver
#============================================
RUN apt-get update -qqy \
  && apt-get -qqy install chromium-driver \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

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
