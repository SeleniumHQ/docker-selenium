ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

USER root

#==============
# Socat to proxy docker.sock when mounted
#==============
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install socat \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

USER ${SEL_UID}

#========================
# Selenium Standalone Docker Configuration
#========================

EXPOSE 4444

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-docker.sh \
    config.toml \
    start-socat.sh \
    /opt/bin/

COPY selenium-grid-docker.conf /etc/supervisor/conf.d/

ENV SE_OTEL_SERVICE_NAME "selenium-node-docker"
