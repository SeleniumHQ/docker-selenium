ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}
ARG MVN_SELENIUM_VERSION
ARG POSTGRESQL_VERSION=42.7.7

#========================
# Selenium SessionMap Configuration
#========================

USER root

RUN if [ -f "/tmp/cs" ]; then \
        java -jar /tmp/cs fetch --classpath --cache /external_jars \
        org.seleniumhq.selenium:selenium-session-map-jdbc:${MVN_SELENIUM_VERSION} \
        org.postgresql:postgresql:${POSTGRESQL_VERSION} \
        org.seleniumhq.selenium:selenium-session-map-redis:${MVN_SELENIUM_VERSION} \
        # Patch specific version for CVEs in the dependencies
        > /external_jars/.classpath_session_map.txt \
        && chmod 664 /external_jars/.classpath_session_map.txt ; \
     fi \
    && rm -fr /root/.cache/*

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
