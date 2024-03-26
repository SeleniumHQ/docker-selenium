ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-base:${VERSION}
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
  && apt-get -qqy --no-install-recommends install ${EDGE_VERSION} \
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
RUN if [ -z "$EDGE_DRIVER_VERSION" ]; \
  then EDGE_MAJOR_VERSION=$(microsoft-edge --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && EDGE_DRIVER_VERSION=$(wget --no-verbose -O - "https://msedgedriver.azureedge.net/LATEST_RELEASE_${EDGE_MAJOR_VERSION}_LINUX" | tr -cd "\11\12\15\40-\176" | tr -d "\r"); \
  fi \
  && echo "Using msedgedriver version: "$EDGE_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/msedgedriver_linux64.zip https://msedgedriver.azureedge.net/$EDGE_DRIVER_VERSION/edgedriver_linux64.zip \
  && rm -rf /opt/selenium/msedgedriver \
  && unzip /tmp/msedgedriver_linux64.zip -d /opt/selenium \
  && rm /tmp/msedgedriver_linux64.zip \
  && mv /opt/selenium/msedgedriver /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION \
  && chmod 755 /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION \
  && ln -fs /opt/selenium/msedgedriver-$EDGE_DRIVER_VERSION /usr/bin/msedgedriver

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "MicrosoftEdge" > /opt/selenium/browser_name
RUN microsoft-edge --version | awk '{print $3}' | cut -d'.' -f1,2 > /opt/selenium/browser_version
RUN echo "\"ms:edgeOptions\": {\"binary\": \"/usr/bin/microsoft-edge\"}" > /opt/selenium/browser_binary_location

ENV SE_OTEL_SERVICE_NAME "selenium-node-edge"
