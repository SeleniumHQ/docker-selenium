#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_HUB_HOST" ]; then
  echo "Using SE_HUB_HOST: ${SE_HUB_HOST}"
  HOST_CONFIG="--host ${SE_HUB_HOST}"
fi

if [ ! -z "$SE_HUB_PORT" ]; then
  echo "Using SE_HUB_PORT: ${SE_HUB_PORT}"
  PORT_CONFIG="--port ${SE_HUB_PORT}"
fi

if [ ! -z "$SE_SUB_PATH" ]; then
  echo "Using SE_SUB_PATH: ${SE_SUB_PATH}"
  SUB_PATH_CONFIG="--sub-path ${SE_SUB_PATH}"
fi

if [ ! -z "$SE_LOG_LEVEL" ]; then
  echo "Appending Selenium options: --log-level ${SE_LOG_LEVEL}"
  SE_OPTS="$SE_OPTS --log-level ${SE_LOG_LEVEL}"
fi

if [ ! -z "$SE_EXTERNAL_URL" ]; then
  echo "Appending Selenium options: --external-url ${SE_EXTERNAL_URL}"
  SE_OPTS="$SE_OPTS --external-url ${SE_EXTERNAL_URL}"
fi

if [ ! -z "$SE_HTTPS_CERTIFICATE" ]; then
  echo "Appending Selenium options: --https-certificate ${SE_HTTPS_CERTIFICATE}"
  SE_OPTS="$SE_OPTS --https-certificate ${SE_HTTPS_CERTIFICATE}"
fi

if [ ! -z "$SE_HTTPS_PRIVATE_KEY" ]; then
  echo "Appending Selenium options: --https-private-key ${SE_HTTPS_PRIVATE_KEY}"
  SE_OPTS="$SE_OPTS --https-private-key ${SE_HTTPS_PRIVATE_KEY}"
fi

if [ ! -z "$SE_JAVA_SSL_TRUST_STORE" ]; then
  echo "Appending Java options: -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
  echo "Appending Java options: -Djavax.net.ssl.trustStorePassword=${SE_JAVA_SSL_TRUST_STORE_PASSWORD}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${SE_JAVA_SSL_TRUST_STORE_PASSWORD}"
  echo "Appending Java options: -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION:-true}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION:-true}"
fi

if [ ! -z "$SE_REGISTRATION_SECRET" ]; then
  echo "Appending Selenium options: --registration-secret ${SE_REGISTRATION_SECRET}"
  SE_OPTS="$SE_OPTS --registration-secret ${SE_REGISTRATION_SECRET}"
fi

if [ ! -z "$SE_DISABLE_UI" ]; then
  echo "Appending Selenium options: --disable-ui ${SE_DISABLE_UI}"
  SE_OPTS="$SE_OPTS --disable-ui ${SE_DISABLE_UI}"
fi

EXTRA_LIBS=""

if [ ! -z "$SE_ENABLE_TRACING" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  [ -n "$EXTRA_LIBS" ] && [ -n "${EXTERNAL_JARS}" ] && EXTRA_LIBS=${EXTRA_LIBS}:
  EXTRA_LIBS="--ext "${EXTRA_LIBS}${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
else
  echo "Tracing is disabled"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} hub \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --relax-checks ${SE_RELAX_CHECKS} \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SUB_PATH_CONFIG} \
  ${SE_OPTS}
