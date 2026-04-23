ARG NAMESPACE=selenium
ARG VERSION=latest
ARG BASE
FROM ${NAMESPACE}/${BASE}:${VERSION}
ARG AUTHORS
LABEL authors=${AUTHORS}

USER root

COPY fluxbox-menu-browser-amd64 fluxbox-menu-browser-aarch64 /etc/X11/fluxbox/

RUN ARCH=$(if [ "$(dpkg --print-architecture)" = "arm64" ]; then echo "aarch64"; else echo "$(dpkg --print-architecture)"; fi) \
    && mv /etc/X11/fluxbox/fluxbox-menu-browser-${ARCH} /etc/X11/fluxbox/fluxbox-menu-browser

USER ${SEL_UID}

ENV SE_OTEL_SERVICE_NAME="selenium-node"