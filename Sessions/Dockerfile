ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium SessionMap Configuration
#========================

EXPOSE 5556

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-sessions.sh \
    /opt/bin/

COPY selenium-grid-sessions.conf /etc/supervisor/conf.d/
