ARG NAMESPACE=selenium
ARG VERSION=latest
ARG BASE=node-base
FROM --platform=linux/amd64 ${NAMESPACE}/${BASE}:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable
#       google-chrome-beta
#       google-chrome-unstable
#============================================
ARG CHROME_VERSION="google-chrome-stable"
#============================================
# Chrome for Testing (CFT)
#============================================
# can specify versions by CFT_VERSION;
#  e.g. STABLE/BETA/DEV/CANARY
#============================================
ARG CFT_VERSION="STABLE"
ARG INSTALL_CFT="false"
COPY --chown="${SEL_UID}:${SEL_GID}" install-chrome.sh update-chrome-components.sh install-chrome-for-testing.sh /opt/bin/
RUN chmod +x /opt/bin/install-chrome.sh /opt/bin/update-chrome-components.sh /opt/bin/install-chrome-for-testing.sh \
    && if [ "${INSTALL_CFT}" = "true" ]; then \
        CFT_VERSION=${CFT_VERSION} /opt/bin/install-chrome-for-testing.sh; \
    else \
        /opt/bin/install-chrome.sh; \
    fi

#=================================
# Chrome Launch Script Wrapper
#=================================
COPY --chown="${SEL_UID}:${SEL_GID}" wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN chmod +x /opt/bin/wrap_chrome_binary \
    && /opt/bin/wrap_chrome_binary

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
ARG CHROME_DRIVER_VERSION
COPY --chown="${SEL_UID}:${SEL_GID}" install-chromedriver.sh /opt/bin/
RUN chmod +x /opt/bin/install-chromedriver.sh \
    && /opt/bin/install-chromedriver.sh

#============================================
# Chrome cleanup script and supervisord file
#============================================
COPY chrome-cleanup.sh /opt/bin/chrome-cleanup.sh
COPY chrome-cleanup.conf /etc/supervisor/conf.d/chrome-cleanup.conf

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN mkdir -p /opt/selenium/browsers/chrome \
    && echo "chrome" > /opt/selenium/browsers/chrome/name \
    && if [ "${INSTALL_CFT}" = "true" ]; then \
        google-chrome --version | awk '{print $5}' > /opt/selenium/browsers/chrome/version; \
    else \
        google-chrome --version | awk '{print $3}' > /opt/selenium/browsers/chrome/version; \
    fi \
    && echo '{"goog:chromeOptions": {"binary": "${SE_BROWSER_BINARY_LOCATION:-/usr/bin/google-chrome}"}}' > /opt/selenium/browsers/chrome/binary_location

ENV SE_OTEL_SERVICE_NAME="selenium-node-chrome" \
    SE_NODE_ENABLE_MANAGED_DOWNLOADS="true" \
    CHROME_FOR_TESTING="${INSTALL_CFT}"
