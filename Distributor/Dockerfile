ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Distributor Configuration
#========================

EXPOSE 5553

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-distributor.sh \
    /opt/bin/

COPY selenium-grid-distributor.conf /etc/supervisor/conf.d/

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT="300" \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL="15" \
# In seconds, maps to "--healthcheck-interval"
    SE_HEALTHCHECK_INTERVAL="120" \
    SE_EVENT_BUS_PUBLISH_PORT="4442" \
    SE_EVENT_BUS_SUBSCRIBE_PORT="4443" \
    SE_SESSIONS_MAP_PORT="5556" \
    SE_SESSION_QUEUE_PORT="5559" \
    SE_DISTRIBUTOR_PORT="5553" \
    SE_OTEL_SERVICE_NAME="selenium-distributor"
