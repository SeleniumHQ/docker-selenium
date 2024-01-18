ARG NAMESPACE
ARG VERSION
ARG AUTHORS
FROM ${NAMESPACE}/base:${VERSION}
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#=================================
# Selenium Event Bus Configuration
#=================================

# Port where events are published
EXPOSE 4442
# Port where to subscribe for events
EXPOSE 4443
# Event Bus port
EXPOSE 5557

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-eventbus.sh \
    /opt/bin/

COPY selenium-grid-eventbus.conf /etc/supervisor/conf.d/
