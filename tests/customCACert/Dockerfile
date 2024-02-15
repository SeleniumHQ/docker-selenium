ARG NAMESPACE=selenium
ARG BASE=node-chrome
ARG VERSION=latest
FROM ${NAMESPACE}/${BASE}:${VERSION}

USER root

ARG CERT_FILE
ARG PERM=577
RUN mkdir -p /usr/share/ca-certificates/extra/
COPY ${CERT_FILE} /usr/share/ca-certificates/extra/
RUN chmod -R ${PERM} /usr/share/ca-certificates/extra/
RUN update-ca-certificates

ARG CERT_SCRIPT
COPY --chown="${SEL_UID}:${SEL_GID}" ${CERT_SCRIPT} /usr/share/ca-certificates/cert-script.sh
RUN chmod +x /usr/share/ca-certificates/cert-script.sh

USER ${SEL_UID}
ARG TRUST_ATTR=TCu,Cu,Tu
RUN bash /usr/share/ca-certificates/cert-script.sh /usr/share/ca-certificates/extra/ ${TRUST_ATTR}
