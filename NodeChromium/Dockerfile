ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-base:${VERSION}
LABEL authors=${AUTHORS}

USER root

#============================================
# Chromium and chromedriver from Debian
# Available versions at: https://packages.debian.org/search?keywords=chromium
#============================================
COPY chromium.pref /etc/apt/preferences.d/chromium.pref

ARG DEBIAN_VERSION=bullseye
ARG REPO_FILE=/etc/apt/sources.list.d/debian.list
ARG KEY_SERVER=keyserver.ubuntu.com
ARG DEBIAN_KEY_LOCATION=/usr/share/keyrings/debian
ARG CHROMIUM_VERSION=120.0.6099.109-1~deb11u1
ARG CHROMEDIVER_VERSION=${CHROMIUM_VERSION}
RUN mkdir /home/seluser/.gnupg && mkdir -p ${DEBIAN_KEY_LOCATION} \
  && gpg --no-default-keyring --keyring ${DEBIAN_KEY_LOCATION}/${DEBIAN_VERSION}.gpg \
         --keyserver ${KEY_SERVER} \
         --recv-keys 0E98404D386FA1D9 \
  && echo "deb [signed-by=${DEBIAN_KEY_LOCATION}/${DEBIAN_VERSION}.gpg] http://deb.debian.org/debian ${DEBIAN_VERSION} main" \
          > ${REPO_FILE} \
  && gpg --no-default-keyring --keyring ${DEBIAN_KEY_LOCATION}/${DEBIAN_VERSION}-updates.gpg \
         --keyserver ${KEY_SERVER} \
         --recv-keys 6ED0E7B82643E131 \
  && echo "deb [signed-by=${DEBIAN_KEY_LOCATION}/${DEBIAN_VERSION}-updates.gpg] http://deb.debian.org/debian ${DEBIAN_VERSION}-updates main" \
          >> ${REPO_FILE} \
  && gpg --no-default-keyring --keyring ${DEBIAN_KEY_LOCATION}/security-${DEBIAN_VERSION}.gpg \
         --keyserver ${KEY_SERVER} \
         --recv-keys 112695A0E562B32A \
  && echo "deb [signed-by=${DEBIAN_KEY_LOCATION}/security-${DEBIAN_VERSION}.gpg] http://deb.debian.org/debian-security ${DEBIAN_VERSION}-security main contrib non-free" \
          >> ${REPO_FILE} \
  && apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install chromium=${CHROMIUM_VERSION} chromium-driver=${CHROMEDIVER_VERSION} \
  && rm ${REPO_FILE} \
  && rm -rf /home/seluser/.gnupg ${DEBIAN_KEY_LOCATION}/ /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Chromium Launch Script Wrapper
#=================================
COPY wrap_chromium_binary /opt/bin/wrap_chromium_binary
RUN /opt/bin/wrap_chromium_binary

USER ${SEL_UID}

#============================================
# Dumping Browser information for config
#============================================
RUN echo "chrome" > /opt/selenium/browser_name
RUN chromium --version | awk '{print $2}' > /opt/selenium/browser_version
RUN echo "\"goog:chromeOptions\": {\"binary\": \"/usr/bin/chromium\"}" > /opt/selenium/browser_binary_location
