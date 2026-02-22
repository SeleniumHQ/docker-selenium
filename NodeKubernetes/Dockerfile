ARG NAMESPACE=selenium
ARG VERSION=latest
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}
ARG MVN_SELENIUM_VERSION=latest.release

USER root

RUN if [ -f "/tmp/cs" ]; then \
        java -jar /tmp/cs fetch --classpath --cache /external_jars \
        org.seleniumhq.selenium:selenium-node-kubernetes:${MVN_SELENIUM_VERSION} \
        > /external_jars/.classpath_node_kubernetes.txt \
        && chmod 664 /external_jars/.classpath_node_kubernetes.txt ; \
     fi \
    && rm -fr /root/.cache/*

#========================
# Selenium Node Kubernetes Configuration
#========================

USER ${SEL_UID}

EXPOSE 4444

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-kubernetes.sh \
    /opt/bin/

COPY --chown="${SEL_UID}:${SEL_GID}" config.toml /opt/selenium/kubernetes.toml

COPY selenium-grid-kubernetes.conf /etc/supervisor/conf.d/

ENV SE_OTEL_SERVICE_NAME="selenium-node-kubernetes" \
    SE_EVENT_BUS_PUBLISH_PORT="4442" \
    SE_EVENT_BUS_SUBSCRIBE_PORT="4443" \
    SE_NODE_KUBERNETES_CONFIG_FILENAME="kubernetes.toml" \
    SE_NODE_ENABLE_MANAGED_DOWNLOADS="true" \
    SE_DYNAMIC_MAX_SESSIONS="" \
    SE_DYNAMIC_OVERRIDE_MAX_SESSIONS=""
