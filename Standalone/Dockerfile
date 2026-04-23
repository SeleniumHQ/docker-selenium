ARG NAMESPACE=selenium
ARG VERSION=latest
ARG BASE=node-base
FROM ${NAMESPACE}/${BASE}:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#====================================
# Scripts to run Selenium Standalone
#====================================
COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-standalone.sh /opt/bin/start-selenium-standalone.sh

#==============================
# Supervisor configuration file
#==============================
COPY selenium.conf /etc/supervisor/conf.d/

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT="300" \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL="15" \
# In seconds, maps to "--healthcheck-interval"
    SE_HEALTHCHECK_INTERVAL="120" \
# Boolean value, maps "--relax-checks"
    SE_RELAX_CHECKS="true" \
    SE_REJECT_UNSUPPORTED_CAPS="true" \
    SE_OTEL_SERVICE_NAME="selenium-standalone" \
    SE_NODE_ENABLE_MANAGED_DOWNLOADS="true" \
    SE_BIND_BUS="true" \
    SE_EVENT_BUS_IMPLEMENTATION=""

EXPOSE 4444
EXPOSE 4443
EXPOSE 4442
