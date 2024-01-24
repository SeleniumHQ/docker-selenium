ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Router Configuration
#========================

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT 300
# In seconds, maps to "--session-retry-interval"
ENV SE_SESSION_RETRY_INTERVAL 0

EXPOSE 4444

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-router.sh \
    /opt/bin/

COPY selenium-grid-router.conf /etc/supervisor/conf.d/
