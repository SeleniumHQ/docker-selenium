ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/node-base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

#============================================
# Microsoft Edge
#============================================
# can specify versions by EDGE_VERSION;
#  e.g. microsoft-edge-beta=88.0.692.0-1
#============================================
ARG EDGE_VERSION="microsoft-edge-stable"
RUN wget -q -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg >/dev/null \
  && echo "deb https://packages.microsoft.com/repos/edge stable main" >> /etc/apt/sources.list.d/microsoft-edge.list \
  && apt-get update -qqy \
  && if echo "${EDGE_VERSION}" | grep -qE "microsoft-edge-stable[_|=][0-9]*"; \
    then \
      EDGE_VERSION=$(echo "$EDGE_VERSION" | tr '=' '_') \
      && wget -qO microsoft-edge.deb "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/${EDGE_VERSION}_$(dpkg --print-architecture).deb" \
      && apt-get -qqy --no-install-recommends install --allow-downgrades ./microsoft-edge.deb \
      && rm -rf microsoft-edge.deb ; \
    else \
      apt-get -qqy --no-install-recommends install ${EDGE_VERSION} ; \
    fi \
  && rm /etc/apt/sources.list.d/microsoft-edge.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Edge Launch Script Wrapper
#=================================
COPY wrap_edge_binary /opt/bin/wrap_edge_binary
RUN /opt/bin/wrap_edge_binary

#============================================
# Edge webdriver
#============================================
# can specify versions by EDGE_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG EDGE_DRIVER_VERSION
RUN DRIVER_ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "linux64"; else echo "linux-aarch64"; fi) \
  && if [ -z "$EDGE_DRIVER_VERSION" ]; \
  then EDGE_MAJOR_VERSION=$(microsoft-edge --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && EDGE_DRIVER_VERSION=$(wget --no-verbose -O - "https://msedgedriver.azureedge.net/LATEST_RELEASE_${EDGE_MAJOR_VERSION}_LINUX" | tr -cd "\11\12\15\40-\176" | tr -d "\r"); \
  fi \
  && echo "Using msedgedriver version: "$EDGE_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/msedgedriver_${DRIVER_ARCH}.zip https://msedgedriver.azureedge.net/$EDGE_DRIVER_VERSION/edgedriver_${DRIVER_ARCH}.zip \
  && rm -rf /opt/selenium/msedgedriver \
  && unzip /tmp/msedgedriver_${DRIVER_ARCH}.zip -d /opt/selenium \
  && rm /tmp/msedgedriver_${DRIVER_ARCH}.zip \
  && mv /opt/selenium/msedgedriver /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION \
  && chmod 755 /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION \
  && ln -fs /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION /usr/bin/msedgedriver

#============================================
# Edge cleanup script and supervisord file
#============================================
COPY edge-cleanup.sh /opt/bin/edge-cleanup.sh
COPY edge-cleanup.conf /etc/supervisor/conf.d/edge-cleanup.conf

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "MicrosoftEdge" > /opt/selenium/browser_name
RUN microsoft-edge --version | awk '{print $3}' > /opt/selenium/browser_version
RUN echo "\"ms:edgeOptions\": {\"binary\": \"/usr/bin/microsoft-edge\"}" > /opt/selenium/browser_binary_location

ENV SE_OTEL_SERVICE_NAME="selenium-node-edge"
