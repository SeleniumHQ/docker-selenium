ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}
ARG MVN_SELENIUM_VERSION
ARG POSTGRESQL_VERSION=42.7.7

#========================
# Selenium SessionQueue Configuration
#========================

USER root

RUN if [ -f "/tmp/cs" ]; then \
        java -jar /tmp/cs fetch --classpath --cache /external_jars \
        org.seleniumhq.selenium:selenium-session-map-jdbc:${MVN_SELENIUM_VERSION} \
        org.postgresql:postgresql:${POSTGRESQL_VERSION} \
        org.seleniumhq.selenium:selenium-session-map-redis:${MVN_SELENIUM_VERSION} \
        > /external_jars/.classpath_session_queue.txt \
        && chmod 664 /external_jars/.classpath_session_queue.txt ; \
     fi \
    && rm -fr /root/.cache/*

COPY --chown="${SEL_UID}:${SEL_GID}" libredis-module.jar /external_jars/
ENV SE_EXTRA_LIBS="/external_jars/libredis-module.jar"

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-session-queue.sh generate_config \
    /opt/bin/
RUN chmod +x /opt/bin/start-selenium-grid-session-queue.sh /opt/bin/generate_config
COPY selenium-grid-session-queue.conf /etc/supervisor/conf.d/

USER ${SEL_UID}

ENV SE_SESSION_REQUEST_TIMEOUT="300" \
    SE_SESSION_RETRY_INTERVAL="15" \
    SE_SESSION_QUEUE_PORT="5559" \
    GENERATE_CONFIG="true" \
    SE_OTEL_SERVICE_NAME="selenium-session-queue"

EXPOSE 5559
