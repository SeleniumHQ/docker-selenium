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
    # Path to the Configfile
    CONFIG_FILE=/opt/selenium/config.toml \
    GENERATE_CONFIG=true \
    SE_SESSIONS_MAP_EXTERNAL_DATASTORE=false
