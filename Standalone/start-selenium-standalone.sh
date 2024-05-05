#!/usr/bin/env bash
#
# IMPORTANT: Change this file only in directory Standalone!

# Start the pulseaudio server
pulseaudio -D --exit-idle-time=-1

# Load the virtual sink and set it as default
pacmd load-module module-virtual-sink sink_name=v1
pacmd set-default-sink v1

# set the monitor of v1 sink to be the default source
pacmd set-default-source v1.monitor

if [ ! -z "$SE_SUB_PATH" ]; then
  echo "Using SE_SUB_PATH: ${SE_SUB_PATH}"
  SUB_PATH_CONFIG="--sub-path ${SE_SUB_PATH}"
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_NODE_ENABLE_MANAGED_DOWNLOADS" ]; then
  echo "Appending Selenium options: --enable-managed-downloads ${SE_NODE_ENABLE_MANAGED_DOWNLOADS}"
  SE_OPTS="$SE_OPTS --enable-managed-downloads ${SE_NODE_ENABLE_MANAGED_DOWNLOADS}"
fi

if [ ! -z "$SE_NODE_ENABLE_CDP" ]; then
  echo "Appending Selenium options: --enable-cdp ${SE_NODE_ENABLE_CDP}"
  SE_OPTS="$SE_OPTS --enable-cdp ${SE_NODE_ENABLE_CDP}"
fi

if [ ! -z "$SE_NODE_REGISTER_PERIOD" ]; then
  echo "Appending Selenium options: --register-period ${SE_NODE_REGISTER_PERIOD}"
  SE_OPTS="$SE_OPTS --register-period ${SE_NODE_REGISTER_PERIOD}"
fi

if [ ! -z "$SE_NODE_REGISTER_CYCLE" ]; then
  echo "Appending Selenium options: --register-cycle ${SE_NODE_REGISTER_CYCLE}"
  SE_OPTS="$SE_OPTS --register-cycle ${SE_NODE_REGISTER_CYCLE}"
fi

if [ ! -z "$SE_NODE_HEARTBEAT_PERIOD" ]; then
  echo "Appending Selenium options: --heartbeat-period ${SE_NODE_HEARTBEAT_PERIOD}"
  SE_OPTS="$SE_OPTS --heartbeat-period ${SE_NODE_HEARTBEAT_PERIOD}"
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

if [ ! -z "$SE_REJECT_UNSUPPORTED_CAPS" ]; then
  echo "Appending Selenium options: --reject-unsupported-caps ${SE_REJECT_UNSUPPORTED_CAPS}"
  SE_OPTS="$SE_OPTS --reject-unsupported-caps ${SE_REJECT_UNSUPPORTED_CAPS}"
fi

if [ ! -z "$SE_NEW_SESSION_THREAD_POOL_SIZE" ]; then
  echo "Appending Selenium options: --newsession-threadpool-size ${SE_NEW_SESSION_THREAD_POOL_SIZE}"
  SE_OPTS="$SE_OPTS --newsession-threadpool-size ${SE_NEW_SESSION_THREAD_POOL_SIZE}"
fi

/opt/bin/generate_config

echo "Selenium Grid Standalone configuration: "
cat /opt/selenium/config.toml
echo "Starting Selenium Grid Standalone..."

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

CHROME_DRIVER_PATH_PROPERTY=-Dwebdriver.chrome.driver=/usr/bin/chromedriver
EDGE_DRIVER_PATH_PROPERTY=-Dwebdriver.edge.driver=/usr/bin/msedgedriver
GECKO_DRIVER_PATH_PROPERTY=-Dwebdriver.gecko.driver=/usr/bin/geckodriver

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  ${CHROME_DRIVER_PATH_PROPERTY} \
  ${EDGE_DRIVER_PATH_PROPERTY} \
  ${GECKO_DRIVER_PATH_PROPERTY} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} standalone \
  --session-request-timeout ${SE_SESSION_REQUEST_TIMEOUT} \
  --session-retry-interval ${SE_SESSION_RETRY_INTERVAL} \
  --healthcheck-interval ${SE_HEALTHCHECK_INTERVAL} \
  --bind-host ${SE_BIND_HOST} \
  --config /opt/selenium/config.toml \
  ${SUB_PATH_CONFIG} \
  ${SE_OPTS}
