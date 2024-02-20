#!/bin/bash

# Start the pulseaudio server
pulseaudio -D --exit-idle-time=-1

# Load the virtual sink and set it as default
pacmd load-module module-virtual-sink sink_name=v1
pacmd set-default-sink v1

# set the monitor of v1 sink to be the default source
pacmd set-default-source v1.monitor

rm -f /tmp/.X*lock

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

if [ ! -z "$SE_OPTS" ]; then
  echo "Appending Selenium options: ${SE_OPTS}"
fi

if [ ! -z "$SE_NODE_SESSION_TIMEOUT" ]; then
  echo "Appending Selenium options: --session-timeout ${SE_NODE_SESSION_TIMEOUT}"
  SE_OPTS="$SE_OPTS --session-timeout ${SE_NODE_SESSION_TIMEOUT}"
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

if [ ! -z "$SE_REGISTRATION_SECRET" ]; then
  echo "Appending Selenium options: --registration-secret ${SE_REGISTRATION_SECRET}"
  SE_OPTS="$SE_OPTS --registration-secret ${SE_REGISTRATION_SECRET}"
fi

if [ "$GENERATE_CONFIG" = true ]; then
  echo "Generating Selenium Config"
  /opt/bin/generate_config
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

echo "Selenium Grid Node configuration: "
cat "$CONFIG_FILE"
echo "Starting Selenium Grid Node..."

CHROME_DRIVER_PATH_PROPERTY=-Dwebdriver.chrome.driver=/usr/bin/chromedriver
EDGE_DRIVER_PATH_PROPERTY=-Dwebdriver.edge.driver=/usr/bin/msedgedriver
GECKO_DRIVER_PATH_PROPERTY=-Dwebdriver.gecko.driver=/usr/bin/geckodriver

java ${JAVA_OPTS:-$SE_JAVA_OPTS} \
  ${CHROME_DRIVER_PATH_PROPERTY} \
  ${EDGE_DRIVER_PATH_PROPERTY} \
  ${GECKO_DRIVER_PATH_PROPERTY} \
  -jar /opt/selenium/selenium-server.jar \
  ${EXTRA_LIBS} node \
  --bind-host ${SE_BIND_HOST} \
  --config "$CONFIG_FILE" \
  ${SE_OPTS}
