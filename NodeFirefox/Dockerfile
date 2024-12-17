ARG NAMESPACE=selenium
ARG VERSION=latest
ARG BASE=node-base
FROM ${NAMESPACE}/${BASE}:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

#============================================
# Firefox cleanup script and supervisord file
#============================================
COPY --chown="${SEL_UID}:${SEL_GID}" firefox-cleanup.sh get_lang_package.sh install-firefox-apt.sh /opt/bin/
COPY --chown="${SEL_UID}:${SEL_GID}" firefox-cleanup.conf /etc/supervisor/conf.d/firefox-cleanup.conf
RUN chmod +x /opt/bin/firefox-cleanup.sh /opt/bin/get_lang_package.sh /opt/bin/install-firefox-apt.sh

#=========
# Firefox
#=========
ARG FIREFOX_VERSION=latest
ARG FIREFOX_DOWNLOAD_URL="https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64-aarch64&lang=en-US"
RUN apt-get update -qqy && \
  if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
    if [ $FIREFOX_VERSION = "latest" ] || [ $FIREFOX_VERSION = "beta-latest" ] || [ $FIREFOX_VERSION = "nightly-latest" ] || [ $FIREFOX_VERSION = "devedition-latest" ] || [ $FIREFOX_VERSION = "esr-latest" ]; then \
      FIREFOX_DOWNLOAD_URL="https://download.mozilla.org/?product=firefox-$FIREFOX_VERSION-ssl&os=linux64&lang=en-US"; \
      /opt/bin/install-firefox-apt.sh \
      && FIREFOX_VERSION=$(echo "-$FIREFOX_VERSION" | sed 's/-latest//') \
      && apt install -y firefox$FIREFOX_VERSION \
      && INSTALL_VIA_APT=true \
      && if [ $FIREFOX_VERSION = "-beta" ] || [ $FIREFOX_VERSION = "-nightly" ] || [ $FIREFOX_VERSION = "-devedition" ] || [ $FIREFOX_VERSION = "-esr" ]; then \
        ln -fs $(which firefox$FIREFOX_VERSION) /usr/bin/firefox ; \
      fi ; \
    else \
      FIREFOX_DOWNLOAD_URL="https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2" ; \
    fi \
  else \
    if [ $FIREFOX_VERSION = "nightly-latest" ]; then \
      /opt/bin/install-firefox-apt.sh \
      && FIREFOX_VERSION=$(echo "-$FIREFOX_VERSION" | sed 's/-latest//') \
      && apt install -y firefox$FIREFOX_VERSION \
      && INSTALL_VIA_APT=true \
      && if [ $FIREFOX_VERSION = "-nightly" ]; then \
        ln -fs $(which firefox$FIREFOX_VERSION) /usr/bin/firefox ; \
      fi ; \
    else \
      FIREFOX_DOWNLOAD_URL="${FIREFOX_DOWNLOAD_URL}" ; \
    fi ; \
  fi && \
  if [ "$INSTALL_VIA_APT" != "true" ]; then \
    apt-get -qqy --no-install-recommends install libavcodec-extra libgtk-3-dev libdbus-glib-1-dev xz-utils \
    && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
    && rm -rf /opt/firefox \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 || (mv /tmp/firefox.tar.bz2 /tmp/firefox.tar.xz && tar -C /opt -xJf /tmp/firefox.tar.xz) \
    && rm -rf /tmp/firefox.tar.bz2 /tmp/firefox.tar.xz \
    && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
    && mkdir -p /opt/firefox-$FIREFOX_VERSION/distribution/extensions \
    && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox ; \
  fi \
  # Download the language pack for Firefox
  && /opt/bin/get_lang_package.sh \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#============
# GeckoDriver
#============
ARG GECKODRIVER_VERSION=latest
RUN LATEST_VERSION=$(curl -sk https://api.github.com/repos/mozilla/geckodriver/releases/latest | jq -r '.tag_name') \
  && DRIVER_ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "linux64"; else echo "linux-aarch64"; fi) \
  && GK_VERSION=$(if [ ${GECKODRIVER_VERSION:-latest} = "latest" ]; then echo "${LATEST_VERSION}"; else echo $GECKODRIVER_VERSION; fi) \
  && echo "Using GeckoDriver version: "$GK_VERSION \
  && wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/${GK_VERSION}/geckodriver-${GK_VERSION}-${DRIVER_ARCH}.tar.gz \
  && rm -rf /opt/geckodriver \
  && tar -C /opt -zxf /tmp/geckodriver.tar.gz \
  && rm /tmp/geckodriver.tar.gz \
  && mv /opt/geckodriver /opt/geckodriver-$GK_VERSION \
  && chmod 755 /opt/geckodriver-$GK_VERSION \
  && ln -fs /opt/geckodriver-$GK_VERSION /usr/bin/geckodriver

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "firefox" > /opt/selenium/browser_name \
    && firefox --version | awk '{print $3}' > /opt/selenium/browser_version \
    && echo "\"moz:firefoxOptions\": {\"binary\": \"/usr/bin/firefox\"}" > /opt/selenium/browser_binary_location

ENV SE_OTEL_SERVICE_NAME="selenium-node-firefox"
