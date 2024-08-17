#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Distributor..."

if [[ -z "${SE_EVENT_BUS_HOST}" ]]; then
  echo "SE_EVENT_BUS_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_PUBLISH_PORT}" ]]; then
  echo "SE_EVENT_BUS_PUBLISH_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_EVENT_BUS_SUBSCRIBE_PORT}" ]]; then
  echo "SE_EVENT_BUS_SUBSCRIBE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSIONS_MAP_HOST}" ]]; then
  echo "SE_SESSIONS_MAP_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSIONS_MAP_PORT}" ]]; then
  echo "SE_SESSIONS_MAP_PORT not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_HOST}" ]]; then
  echo "SE_SESSION_QUEUE_HOST not set, exiting!" 1>&2
  exit 1
fi

if [[ -z "${SE_SESSION_QUEUE_PORT}" ]]; then
  echo "SE_SESSION_QUEUE_PORT not set, exiting!" 1>&2
  exit 1
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_DISTRIBUTOR_HOST" ]; then
  echo "Using SE_DISTRIBUTOR_HOST: ${SE_DISTRIBUTOR_HOST}"
  HOST_CONFIG="--host ${SE_DISTRIBUTOR_HOST}"
fi

if [ ! -z "$SE_DISTRIBUTOR_PORT" ]; then
  echo "Using SE_DISTRIBUTOR_PORT: ${SE_DISTRIBUTOR_PORT}"
  PORT_CONFIG="--port ${SE_DISTRIBUTOR_PORT}"
fi

if [ ! -z "$SE_LOG_LEVEL" ]; then
  echo "Appending Selenium options: --log-level ${SE_LOG_LEVEL}"
  SE_OPTS="$SE_OPTS --log-level ${SE_LOG_LEVEL}"
fi

if [ ! -z "$SE_HTTP_LOGS" ]; then
  echo "Appending Selenium options: --http-logs ${SE_HTTP_LOGS}"
  SE_OPTS="$SE_OPTS --http-logs ${SE_HTTP_LOGS}"
fi

if [ ! -z "$SE_STRUCTURED_LOGS" ]; then
  echo "Appending Selenium options: --structured-logs ${SE_STRUCTURED_LOGS}"
  SE_OPTS="$SE_OPTS --structured-logs ${SE_STRUCTURED_LOGS}"
fi

if [ ! -z "$SE_EXTERNAL_URL" ]; then
  echo "Appending Selenium options: --external-url ${SE_EXTERNAL_URL}"
  SE_OPTS="$SE_OPTS --external-url ${SE_EXTERNAL_URL}"
fi

if [ "${SE_ENABLE_TLS}" = "true" ]; then
  # Configure truststore for the server
  if [ ! -z "$SE_JAVA_SSL_TRUST_STORE" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStore=${SE_JAVA_SSL_TRUST_STORE}"
  fi
  if [ -f "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Getting Truststore password from ${SE_JAVA_SSL_TRUST_STORE_PASSWORD} to set Java options: -Djavax.net.ssl.trustStorePassword"
    SE_JAVA_SSL_TRUST_STORE_PASSWORD="$(cat ${SE_JAVA_SSL_TRUST_STORE_PASSWORD})"
  fi
  if [ ! -z "${SE_JAVA_SSL_TRUST_STORE_PASSWORD}" ]; then
    echo "Appending Java options: -Djavax.net.ssl.trustStorePassword=$(mask ${SE_JAVA_SSL_TRUST_STORE_PASSWORD})"
    SE_JAVA_OPTS="$SE_JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${SE_JAVA_SSL_TRUST_STORE_PASSWORD}"
  fi
  echo "Appending Java options: -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Djdk.internal.httpclient.disableHostnameVerification=${SE_JAVA_DISABLE_HOSTNAME_VERIFICATION}"
  # Configure certificate and private key for component communication
  if [ ! -z "$SE_HTTPS_CERTIFICATE" ]; then
    echo "Appending Selenium options: --https-certificate ${SE_HTTPS_CERTIFICATE}"
    SE_OPTS="$SE_OPTS --https-certificate ${SE_HTTPS_CERTIFICATE}"
  fi
  if [ ! -z "$SE_HTTPS_PRIVATE_KEY" ]; then
    echo "Appending Selenium options: --https-private-key ${SE_HTTPS_PRIVATE_KEY}"
    SE_OPTS="$SE_OPTS --https-private-key ${SE_HTTPS_PRIVATE_KEY}"
  fi
fi

if [ ! -z "$SE_REGISTRATION_SECRET" ]; then
  echo "Appending Selenium options: --registration-secret $(mask ${SE_REGISTRATION_SECRET})"
  SE_OPTS="$SE_OPTS --registration-secret ${SE_REGISTRATION_SECRET}"
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
  SE_OPTS="$SE_OPTS --tracing false"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Dwebdriver.remote.enableTracing=false"
  echo "Tracing is disabled"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} distributor \
  --sessions-host "${SE_SESSIONS_MAP_HOST}" --sessions-port "${SE_SESSIONS_MAP_PORT}" \
  --sessionqueue-host "${SE_SESSION_QUEUE_HOST}" --sessionqueue-port "${SE_SESSION_QUEUE_PORT}" \
  --publish-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_PUBLISH_PORT}" \
  --subscribe-events tcp://"${SE_EVENT_BUS_HOST}":"${SE_EVENT_BUS_SUBSCRIBE_PORT}" \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --healthcheck-interval ${SE_HEALTHCHECK_INTERVAL} \
  --bind-host ${SE_BIND_HOST} \
  --bind-bus false \
  ${HOST_CONFIG} \
  ${PORT_CONFIG} \
  ${SE_OPTS}
