ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium SessionQueue Configuration
#========================

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT="300" \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL="15" \
    SE_SESSION_QUEUE_PORT="5559" \
    SE_OTEL_SERVICE_NAME="selenium-session-queue" \
    SE_SESSION_QUEUE_IMPLEMENTATION="" \
    SE_SESSION_QUEUE_BACKEND_URL=""

EXPOSE 5559

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-session-queue.sh \
    /opt/bin/

COPY selenium-grid-session-queue.conf /etc/supervisor/conf.d/
