ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-docker:${VERSION}
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Standalone Docker Configuration
#========================

EXPOSE 4444

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-docker.sh /opt/bin/

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT 300
# In seconds, maps to "--session-retry-interval"
ENV SE_SESSION_RETRY_INTERVAL 15
# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true
