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

if [ ! -z "$SE_STRUCTURED_LOGS" ]; then
  echo "Appending Selenium options: --structured-logs ${SE_STRUCTURED_LOGS}"
  SE_OPTS="$SE_OPTS --structured-logs ${SE_STRUCTURED_LOGS}"
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

if [ ! -z "$SE_ROUTER_USERNAME" ]; then
  echo "Appending Selenium options: --username ${SE_ROUTER_USERNAME}"
  SE_OPTS="$SE_OPTS --username ${SE_ROUTER_USERNAME}"
fi

if [ ! -z "$SE_ROUTER_PASSWORD" ]; then
  echo "Appending Selenium options: --password ${SE_ROUTER_PASSWORD}"
  SE_OPTS="$SE_OPTS --password ${SE_ROUTER_PASSWORD}"
fi

if [ ! -z "$SE_REJECT_UNSUPPORTED_CAPS" ]; then
  echo "Appending Selenium options: --reject-unsupported-caps ${SE_REJECT_UNSUPPORTED_CAPS}"
  SE_OPTS="$SE_OPTS --reject-unsupported-caps ${SE_REJECT_UNSUPPORTED_CAPS}"
fi

if [ ! -z "$SE_NEW_SESSION_THREAD_POOL_SIZE" ]; then
  echo "Appending Selenium options: --newsession-threadpool-size ${SE_NEW_SESSION_THREAD_POOL_SIZE}"
  SE_OPTS="$SE_OPTS --newsession-threadpool-size ${SE_NEW_SESSION_THREAD_POOL_SIZE}"
fi

EXTRA_LIBS=""

if [ "$SE_ENABLE_TRACING" = "true" ]; then
  EXTERNAL_JARS=$(</external_jars/.classpath.txt)
  [ -n "$EXTRA_LIBS" ] && [ -n "${EXTERNAL_JARS}" ] && EXTRA_LIBS=${EXTRA_LIBS}:
  EXTRA_LIBS="--ext "${EXTRA_LIBS}${EXTERNAL_JARS}
  echo "Tracing is enabled"
  echo "Classpath will be enriched with these external jars : " ${EXTRA_LIBS}
  if [ -n "$SE_OTEL_SERVICE_NAME" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.resource.attributes=service.name=${SE_OTEL_SERVICE_NAME}"
  fi
  if [ -n "$SE_OTEL_TRACES_EXPORTER" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.traces.exporter=${SE_OTEL_TRACES_EXPORTER}"
  fi
  if [ -n "$SE_OTEL_EXPORTER_ENDPOINT" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.exporter.otlp.endpoint=${SE_OTEL_EXPORTER_ENDPOINT}"
  fi
  if [ -n "$SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED" ]; then
    SE_OTEL_JVM_ARGS="$SE_OTEL_JVM_ARGS -Dotel.java.global-autoconfigure.enabled=${SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED}"
  fi
  if [ -n "$SE_OTEL_JVM_ARGS" ]; then
    echo "List arguments for OpenTelemetry: ${SE_OTEL_JVM_ARGS}"
    SE_JAVA_OPTS="$SE_JAVA_OPTS ${SE_OTEL_JVM_ARGS}"
  fi
else
  echo "Tracing is disabled"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} hub \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --healthcheck-interval ${SE_HEALTHCHECK_INTERVAL} \
  --relax-checks ${SE_RELAX_CHECKS} \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SUB_PATH_CONFIG} \
  ${SE_OPTS}
