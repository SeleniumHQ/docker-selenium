ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
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
ENV SE_SESSION_REQUEST_TIMEOUT 300
# In seconds, maps to "--session-retry-interval"
ENV SE_SESSION_RETRY_INTERVAL 15

ENV SE_OTEL_SERVICE_NAME "selenium-distributor"
