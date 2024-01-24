ARG NAMESPACE
ARG VERSION
ARG AUTHORS
ARG BASE
FROM ${NAMESPACE}/${BASE}:${VERSION}
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

# Boolean value, maps "--relax-checks"
ENV SE_RELAX_CHECKS true

EXPOSE 4444


