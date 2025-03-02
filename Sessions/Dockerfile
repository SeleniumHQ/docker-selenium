ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

#========================
# Selenium SessionMap Configuration
#========================

USER root

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-sessions.sh generate_config \
    /opt/bin/
RUN chmod +x /opt/bin/start-selenium-grid-sessions.sh /opt/bin/generate_config

COPY selenium-grid-sessions.conf /etc/supervisor/conf.d/

USER ${SEL_UID}

EXPOSE 5556

ENV SE_OTEL_SERVICE_NAME="selenium-session-map" \
    GENERATE_CONFIG="true" \
    SE_EVENT_BUS_PUBLISH_PORT="4442" \
    SE_EVENT_BUS_SUBSCRIBE_PORT="4443" \
    SE_SESSIONS_MAP_PORT="5556" \
    SE_SESSIONS_MAP_EXTERNAL_DATASTORE="false"
