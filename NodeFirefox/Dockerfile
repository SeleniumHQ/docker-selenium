ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/node-base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

#=========
# Firefox
#=========
ARG FIREFOX_VERSION=latest
RUN if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        FIREFOX_DOWNLOAD_URL=$(if [ $FIREFOX_VERSION = "latest" ] || [ $FIREFOX_VERSION = "beta-latest" ] || [ $FIREFOX_VERSION = "nightly-latest" ] || [ $FIREFOX_VERSION = "devedition-latest" ] || [ $FIREFOX_VERSION = "esr-latest" ]; then echo "https://download.mozilla.org/?product=firefox-$FIREFOX_VERSION-ssl&os=linux64&lang=en-US"; else echo "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2"; fi) ; \
    else \
        FIREFOX_DOWNLOAD_URL="https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64-aarch64&lang=en-US" ; \
    fi \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install libavcodec-extra libgtk-3-dev libdbus-glib-1-dev \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/* ${HOME}/firefox \
  && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
  && tar -C ${HOME} -xjf /tmp/firefox.tar.bz2 \
  && rm /tmp/firefox.tar.bz2 \
  && mkdir -p ${HOME}/firefox/distribution/extensions \
  && setfacl -Rm u:${SEL_USER}:rwx ${HOME}/firefox \
  && setfacl -Rm g:${SEL_GROUP}:rwx ${HOME}/firefox \
  && ln -fs ${HOME}/firefox/firefox /usr/bin/firefox

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

#============================================
# Firefox cleanup script and supervisord file
#============================================
COPY --chown="${SEL_UID}:${SEL_GID}" firefox-cleanup.sh get_lang_package.sh /opt/bin/
COPY --chown="${SEL_UID}:${SEL_GID}" firefox-cleanup.conf /etc/supervisor/conf.d/firefox-cleanup.conf
RUN chmod +x /opt/bin/firefox-cleanup.sh /opt/bin/get_lang_package.sh

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "firefox" > /opt/selenium/browser_name \
    && firefox --version | awk '{print $3}' > /opt/selenium/browser_version \
    && echo "\"moz:firefoxOptions\": {\"binary\": \"/usr/bin/firefox\"}" > /opt/selenium/browser_binary_location \
    # Download the language pack for Firefox
    && /opt/bin/get_lang_package.sh

ENV SE_OTEL_SERVICE_NAME="selenium-node-firefox"
