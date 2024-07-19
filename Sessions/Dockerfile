ARG NAMESPACE
ARG VERSION
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium SessionMap Configuration
#========================

EXPOSE 5556

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-sessions.sh \
    /opt/bin/

COPY selenium-grid-sessions.conf /etc/supervisor/conf.d/

ENV SE_OTEL_SERVICE_NAME="selenium-session-map"
