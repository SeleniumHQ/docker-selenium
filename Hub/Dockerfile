ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Hub Configuration
#========================

EXPOSE 4442
EXPOSE 4443
EXPOSE 4444

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT 300
# In seconds, maps to "--session-retry-interval"
ENV SE_SESSION_RETRY_INTERVAL 15
# In seconds, maps to "--healthcheck-interval"
ENV SE_HEALTHCHECK_INTERVAL 120
# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-hub.sh \
    /opt/bin/

COPY selenium-grid-hub.conf /etc/supervisor/conf.d/

ENV SE_OTEL_SERVICE_NAME "selenium-hub"
