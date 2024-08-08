ARG NAMESPACE
ARG VERSION
ARG BASE
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

# Copying configuration script generator
COPY --chown="${SEL_UID}:${SEL_GID}" generate_config /opt/bin/generate_config

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT=300 \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL=15 \
# In seconds, maps to "--healthcheck-interval"
    SE_HEALTHCHECK_INTERVAL=120 \
# Boolean value, maps "--relax-checks"
    SE_RELAX_CHECKS=true \
# Boolean value, maps "--reject-unsupported-caps", defaults to true because a Standalone Grid is not waiting for Nodes to register
    SE_REJECT_UNSUPPORTED_CAPS=true \
    SE_OTEL_SERVICE_NAME="selenium-standalone"

EXPOSE 4444
