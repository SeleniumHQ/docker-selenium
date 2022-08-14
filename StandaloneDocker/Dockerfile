ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/node-docker:${VERSION}
LABEL authors=${AUTHORS}

USER 1200

#========================
# Selenium Standalone Docker Configuration
#========================

EXPOSE 4444

COPY start-selenium-grid-docker.sh /opt/bin/

# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true
