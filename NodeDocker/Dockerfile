ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
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
    start-socat.sh \
    /opt/bin/

COPY --chown="${SEL_UID}:${SEL_GID}" config.toml /opt/selenium/

COPY selenium-grid-docker.conf /etc/supervisor/conf.d/

ENV SE_OTEL_SERVICE_NAME="selenium-node-docker" \
    SE_EVENT_BUS_PUBLISH_PORT="4442" \
    SE_EVENT_BUS_SUBSCRIBE_PORT="4443"
