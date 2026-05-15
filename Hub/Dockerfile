ARG NAMESPACE=selenium
ARG VERSION=latest
#========================
# Exporter build stage
#========================
FROM golang:1.26-alpine AS exporter-builder
WORKDIR /src
COPY --from=exporter-src . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /selenium-grid-exporter .

#========================
# Selenium Hub image
#========================
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Hub Configuration
#========================

EXPOSE 4442
EXPOSE 4443
EXPOSE 4444
EXPOSE 9615

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT="300" \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL="15" \
# In seconds, maps to "--healthcheck-interval"
    SE_HEALTHCHECK_INTERVAL="120" \
# Boolean value, maps "--relax-checks"
    SE_RELAX_CHECKS="true" \
    SE_HUB_PORT="4444" \
    SE_TCP_TUNNEL="false" \
    SE_OTEL_SERVICE_NAME="selenium-hub"

COPY --from=exporter-builder --chown="${SEL_UID}:${SEL_GID}" /selenium-grid-exporter /opt/bin/selenium-grid-exporter

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-hub.sh \
    /opt/bin/

COPY selenium-grid-hub.conf /etc/supervisor/conf.d/
