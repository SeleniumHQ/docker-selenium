ARG NAMESPACE=selenium
ARG BASE=node-chrome
ARG VERSION=latest
FROM ${NAMESPACE}/${BASE}:${VERSION}
ARG CERT_FILE
ARG CERT_TRUST_ATTR=TCu,Cu,Tu
ARG CERT_TARGET_COPY=/opt/selenium/secrets

COPY ${CERT_FILE} ${CERT_TARGET_COPY}
RUN /opt/bin/add-jks-helper.sh -d ${CERT_TARGET_COPY} \
    && /opt/bin/add-cert-helper.sh -d ${CERT_TARGET_COPY} ${CERT_TRUST_ATTR}
