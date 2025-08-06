ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}
ARG MVN_SELENIUM_VERSION
ARG POSTGRESQL_VERSION=42.7.7

#========================
# Selenium Distributor Configuration
#========================

USER root

RUN if [ -f "/tmp/cs" ]; then \
        java -jar /tmp/cs fetch --classpath --cache /external_jars \
        org.seleniumhq.selenium:selenium-session-map-jdbc:${MVN_SELENIUM_VERSION} \
        org.postgresql:postgresql:${POSTGRESQL_VERSION} \
        org.seleniumhq.selenium:selenium-session-map-redis:${MVN_SELENIUM_VERSION} \
        > /external_jars/.classpath_distributor.txt \
        && chmod 664 /external_jars/.classpath_distributor.txt ; \
     fi \
    && rm -fr /root/.cache/*

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-distributor.sh \
    /opt/bin/

COPY selenium-grid-distributor.conf /etc/supervisor/conf.d/

USER ${SEL_UID}

EXPOSE 5553

ENV SE_SESSION_REQUEST_TIMEOUT="300" \
    SE_SESSION_RETRY_INTERVAL="15" \
    SE_HEALTHCHECK_INTERVAL="120" \
    SE_EVENT_BUS_PUBLISH_PORT="4442" \
    SE_EVENT_BUS_SUBSCRIBE_PORT="4443" \
    SE_SESSIONS_MAP_PORT="5556" \
    SE_SESSION_QUEUE_PORT="5559" \
    SE_DISTRIBUTOR_PORT="5553" \
    SE_OTEL_SERVICE_NAME="selenium-distributor"
