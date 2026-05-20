ARG NAMESPACE=selenium
ARG VERSION=latest
#========================
# Exporter build stage
#========================
FROM golang:latest AS exporter-builder
WORKDIR /src
COPY --from=exporter-src go.mod go.sum ./
RUN go mod download
COPY --from=exporter-src . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /selenium-grid-exporter .

#========================
# Selenium Router image
#========================
FROM ${NAMESPACE}/base:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER ${SEL_UID}

#========================
# Selenium Router Configuration
#========================

# In seconds, maps to "--session-request-timeout"
ENV SE_SESSION_REQUEST_TIMEOUT="300" \
# In seconds, maps to "--session-retry-interval"
    SE_SESSION_RETRY_INTERVAL="15" \
    SE_DISTRIBUTOR_PORT="5553" \
    SE_SESSIONS_MAP_PORT="5556" \
    SE_SESSION_QUEUE_PORT="5559" \
    SE_ROUTER_PORT="4444" \
    SE_TCP_TUNNEL="false" \
    SE_OTEL_SERVICE_NAME="selenium-router"

EXPOSE 4444
EXPOSE 9615

COPY --from=exporter-builder --chown="${SEL_UID}:${SEL_GID}" /selenium-grid-exporter /opt/bin/selenium-grid-exporter

COPY --chown="${SEL_UID}:${SEL_GID}" start-selenium-grid-router.sh \
    /opt/bin/

COPY selenium-grid-router.conf /etc/supervisor/conf.d/
