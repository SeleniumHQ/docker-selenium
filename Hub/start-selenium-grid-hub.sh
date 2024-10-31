#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
set -e

echo "Starting Selenium Grid Hub..."

function append_se_opts() {
  local option="${1}"
  local value="${2:-""}"
  local log_message="${3:-true}"
  if [[ "${SE_OPTS}" != *"${option}"* ]]; then
    if [ "${log_message}" = "true" ]; then
      echo "Appending Selenium option: ${option} ${value}"
    else
      echo "Appending Selenium option: ${option} $(mask ${value})"
    fi
    SE_OPTS="${SE_OPTS} ${option}"
    if [ ! -z "${value}" ]; then
      SE_OPTS="${SE_OPTS} ${value}"
    fi
  else
    echo "Selenium option: ${option} already set in env variable SE_OPTS. Ignore new option: ${option} ${value}"
  fi
}

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_HUB_HOST" ]; then
  append_se_opts "--host" "${SE_HUB_HOST}"
fi

if [ ! -z "$SE_HUB_PORT" ]; then
  append_se_opts "--port" "${SE_HUB_PORT}"
fi

if [ ! -z "$SE_SUB_PATH" ]; then
  append_se_opts "--sub-path" "${SE_SUB_PATH}"
fi

if [ ! -z "$SE_LOG_LEVEL" ]; then
  append_se_opts "--log-level" "${SE_LOG_LEVEL}"
fi

if [ ! -z "$SE_HTTP_LOGS" ]; then
  append_se_opts "--http-logs" "${SE_HTTP_LOGS}"
fi

if [ ! -z "$SE_STRUCTURED_LOGS" ]; then
  append_se_opts "--structured-logs" "${SE_STRUCTURED_LOGS}"
fi

if [ ! -z "$SE_EXTERNAL_URL" ]; then
  append_se_opts "--external-url" "${SE_EXTERNAL_URL}"
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
    append_se_opts "--https-certificate" "${SE_HTTPS_CERTIFICATE}"
  fi
  if [ ! -z "$SE_HTTPS_PRIVATE_KEY" ]; then
    append_se_opts "--https-private-key" "${SE_HTTPS_PRIVATE_KEY}"
  fi
fi

if [ ! -z "$SE_REGISTRATION_SECRET" ]; then
  append_se_opts "--registration-secret" "${SE_REGISTRATION_SECRET}" "false"
fi

if [ ! -z "$SE_DISABLE_UI" ]; then
  append_se_opts "--disable-ui" "${SE_DISABLE_UI}"
fi

if [ ! -z "$SE_ROUTER_USERNAME" ]; then
  append_se_opts "--username" "${SE_ROUTER_USERNAME}" "false"
fi

if [ ! -z "$SE_ROUTER_PASSWORD" ]; then
  append_se_opts "--password" "${SE_ROUTER_PASSWORD}" "false"
fi

if [ ! -z "$SE_REJECT_UNSUPPORTED_CAPS" ]; then
  append_se_opts "--reject-unsupported-caps" "${SE_REJECT_UNSUPPORTED_CAPS}"
fi

if [ ! -z "$SE_NEW_SESSION_THREAD_POOL_SIZE" ]; then
  append_se_opts "--newsession-threadpool-size" "${SE_NEW_SESSION_THREAD_POOL_SIZE}"
fi

if [ ! -z "${SE_SESSION_REQUEST_TIMEOUT}" ]; then
  append_se_opts "--session-request-timeout" "${SE_SESSION_REQUEST_TIMEOUT}"
fi

if [ ! -z "${SE_SESSION_RETRY_INTERVAL}" ]; then
  append_se_opts "--session-retry-interval" "${SE_SESSION_RETRY_INTERVAL}"
fi

if [ ! -z "${SE_HEALTHCHECK_INTERVAL}" ]; then
  append_se_opts "--healthcheck-interval" "${SE_HEALTHCHECK_INTERVAL}"
fi

if [ ! -z "${SE_RELAX_CHECKS}" ]; then
  append_se_opts "--relax-checks" "${SE_RELAX_CHECKS}"
fi

if [ ! -z "${SE_BIND_HOST}" ]; then
  append_se_opts "--bind-host" "${SE_BIND_HOST}"
fi

if [ ! -z "${CONFIG_FILE}" ]; then
  append_se_opts "--config" "${CONFIG_FILE}"
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
  append_se_opts "--tracing" "false"
  SE_JAVA_OPTS="$SE_JAVA_OPTS -Dwebdriver.remote.enableTracing=false"
  echo "Tracing is disabled"
fi

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} \
  hub \
  ${SE_OPTS}
