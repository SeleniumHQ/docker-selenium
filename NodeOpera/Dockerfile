# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.txt INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM selenium/node-base:3.141.59-20200326
LABEL authors=SeleniumHQ

USER root


#============================================
# Opera
#============================================
# can specify versions by OPERA_VERSION;
#  e.g. opera-stable=60.0.3255.109
#       opera-beta=60.0.3255.103
#       opera-developer=62.0.3323.0
#       opera=12.16.1860
#       opera-next=12.16.1860
#       latest (equivalent to opera-stable)
#       opera-beta  (pull latest beta)
#============================================
ARG OPERA_VERSION="opera-stable"
RUN wget -q -O - https://deb.opera.com/archive.key | apt-key add - \
  && echo "deb https://deb.opera.com/opera-stable/ stable non-free" >> /etc/apt/sources.list.d/opera-stable.list \
  && apt-get update -qqy \
  && apt-get -qqy install \
    ${OPERA_VERSION:-opera-stable} \
  && dpkg-divert --divert /usr/lib/x86_64-linux-gnu/opera/libffmpeg.so.orig \
     --package ${OPERA_VERSION:-opera-stable} --rename --add \
     /usr/lib/x86_64-linux-gnu/opera/libffmpeg.so \
  && ln -sf /usr/lib/chromium-browser/libffmpeg.so /usr/lib/x86_64-linux-gnu/opera/libffmpeg.so \
  && rm /etc/apt/sources.list.d/opera-stable.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#=================================
# Opera Launch Script Wrapper
#=================================
COPY wrap_opera_binary /opt/bin/wrap_opera_binary
RUN /opt/bin/wrap_opera_binary

USER seluser

#=====================
# Opera webdriver
#=====================
# can specify versions by OPERA_DRIVER_VERSION
# Latest released version will be used by default
#=====================
ARG OPERA_DRIVER_VERSION
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/operasoftware/operachromiumdriver/releases/latest | jq .name -r) \
  && [ -z "$OPERA_DRIVER_VERSION" ] && OPERA_DRIVER_VERSION=$LATEST_VERSION \
  && echo "Using operadriver version: "$OPERA_DRIVER_VERSION \
  && wget --no-verbose -O /tmp/operadriver_linux64.zip https://github.com/operasoftware/operachromiumdriver/releases/download/v.${OPERA_DRIVER_VERSION}/operadriver_linux64.zip \
  && rm -rf /opt/selenium/operadriver \
  && unzip /tmp/operadriver_linux64.zip -d /tmp/ \
  && mv /tmp/operadriver_linux64/operadriver /opt/selenium/operadriver-${OPERA_DRIVER_VERSION} \
  && rm -rf /tmp/operadriver_linux64* \
  && chmod 755 /opt/selenium/operadriver-${OPERA_DRIVER_VERSION} \
  && sudo ln -fs /opt/selenium/operadriver-${OPERA_DRIVER_VERSION} /usr/bin/operadriver

COPY generate_config /opt/bin/generate_config

# Generating a default config during build time
RUN /opt/bin/generate_config > /opt/selenium/config.json
