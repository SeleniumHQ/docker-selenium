| ENV variable | Default value | Description | CLI option represent |
|--------------|---------------|-------------|----------------------|
| SE_SCREEN_WIDTH | 1920 | Use in Node to set the screen width |  |
| SE_SCREEN_HEIGHT | 1080 | Use in Node to set the screen height |  |
| SE_VIDEO_FILE_NAME | video.mp4 | Use in function video recording to set the output file name. Set `auto` for dynamic file name relying on test metadata |  |
| SE_FRAME_RATE | 15 | Set the frame rate for FFmpeg in video recording |  |
| SE_CODEC | libx264 | Set the codec for FFmpeg in video recording |  |
| SE_PRESET | -preset ultrafast | Set the preset for FFmpeg in video recording |  |
| SE_VIDEO_UPLOAD_ENABLED | false | Enable video upload |  |
| SE_VIDEO_INTERNAL_UPLOAD | true | Enable video upload using Rclone in the same recorder container |  |
| SE_UPLOAD_DESTINATION_PREFIX |  | Remote name and destination path to upload |  |
| SE_UPLOAD_PIPE_FILE_NAME |  | Set the pipe file name for video upload to consume |  |
| SE_SERVER_PROTOCOL | http | Protocol for communication between components |  |
| SE_VIDEO_POLL_INTERVAL | 1 |  |  |
| SE_VIDEO_WAIT_ATTEMPTS |  |  |  |
| SE_VIDEO_FILE_READY_WAIT_ATTEMPTS |  |  |  |
| SE_VIDEO_WAIT_UPLOADER_SHUTDOWN_ATTEMPTS |  |  |  |
| SE_LOG_TIMESTAMP_FORMAT | %Y-%m-%d %H:%M:%S,%3N |  |  |
| SE_VIDEO_RECORD_STANDALONE |  |  |  |
| SE_NODE_PORT |  |  | --port |
| SE_ROUTER_USERNAME |  | Set the username for basic authentication | --username |
| SE_ROUTER_PASSWORD |  | Set the password for basic authentication |  |
| SE_SUPERVISORD_PID_FILE | /tmp/supervisord.pid | Default pid file will be created by supervisord |  |
| SE_DRAIN_AFTER_SESSION_COUNT | 0 | Drain and detach node from grid after session count exceeds | --drain-after-session-count |
| SE_SUB_PATH |  | A sub-path that should be considered for all user facing routes on the Hub/Router/Standalone | --sub-path |
| SE_NODE_GRID_URL |  | Node config, public URL of the Grid as a whole (typically the address of the Hub or the Router) | --grid-url |
| SE_HUB_HOST |  | Hub config, host address the Hub should listen on | --host |
| SE_ROUTER_HOST |  | Router config, host address the Router should listen on | --host |
| SE_HUB_PORT | 4444 | Hub config, port the Hub should listen on (default 4444) | --port |
| SE_ROUTER_PORT | 4444 | Router config, port the Router should listen on (default 4444) | --port |
| SE_NODE_GRID_GRAPHQL_URL |  | Video recording config, GraphQL URL to query test metadata for dynamic file name |  |
| SE_VIDEO_FILE_NAME_TRIM_REGEX | [:alnum:]-_ | Bash regex to trim the file name if it is too long |  |
| SE_VIDEO_FILE_NAME_SUFFIX |  | Append a suffix session id along with test metadata |  |
| SE_RCLONE_CONFIG |  |  |  |
| SE_UPLOAD_COMMAND |  |  |  |
| SE_UPLOAD_OPTS |  |  |  |
| SE_UPLOAD_RETAIN_LOCAL_FILE |  |  |  |
| SE_VIDEO_UPLOAD_BATCH_CHECK |  |  |  |
| SE_RCLONE_ |  |  |  |
| SE_OPTS |  |  |  |
| SE_EVENT_BUS_HOST |  |  |  |
| SE_EVENT_BUS_PORT | 5557 |  |  |
| SE_LOG_LEVEL | INFO |  | --log-level |
| SE_HTTP_LOGS | false |  | --http-logs |
| SE_STRUCTURED_LOGS | false |  | --structured-logs |
| SE_EXTERNAL_URL |  |  | --external-url |
| SE_ENABLE_TLS | false |  |  |
| SE_JAVA_SSL_TRUST_STORE | /opt/selenium/secrets/server.jks |  |  |
| SE_JAVA_OPTS |  |  |  |
| SE_JAVA_SSL_TRUST_STORE_PASSWORD | /opt/selenium/secrets/server.pass |  |  |
| SE_JAVA_DISABLE_HOSTNAME_VERIFICATION | true |  |  |
| SE_HTTPS_CERTIFICATE | /opt/selenium/secrets/tls.crt |  | --https-certificate |
| SE_HTTPS_PRIVATE_KEY | /opt/selenium/secrets/tls.key |  | --https-private-key |
| SE_ENABLE_TRACING | true |  | --tracing |
| SE_OTEL_EXPORTER_ENDPOINT |  |  | -Dotel.exporter.otlp.endpoint= |
| SE_OTEL_SERVICE_NAME | selenium-event-bus |  | -Dotel.resource.attributes=service.name= |
| SE_OTEL_JVM_ARGS |  |  |  |
| SE_OTEL_TRACES_EXPORTER | otlp |  | -Dotel.traces.exporter |
| SE_OTEL_JAVA_GLOBAL_AUTOCONFIGURE_ENABLED | true |  |  |
| SE_JAVA_HTTPCLIENT_VERSION | HTTP_1_1 |  | -Dwebdriver.httpclient.version |
| SE_JAVA_OPTS_DEFAULT |  |  |  |
| SE_JAVA_HEAP_DUMP | false |  |  |
| SE_BIND_HOST | false |  |  |
| SE_SCREEN_DEPTH | 24 |  |  |
| SE_SCREEN_DPI | 96 |  |  |
| SE_START_XVFB | true |  |  |
| SE_START_VNC | true |  |  |
| SE_START_NO_VNC | true |  |  |
| SE_VNC_ULIMIT |  |  |  |
| SE_NO_VNC_PORT | 7900 |  |  |
| SE_VNC_PORT | 5900 |  |  |
| SE_VNC_NO_PASSWORD |  |  |  |
| SE_VNC_VIEW_ONLY |  |  |  |
| SE_VNC_PASSWORD |  |  |  |
| SE_EVENT_BUS_PUBLISH_PORT | 4442 |  |  |
| SE_EVENT_BUS_SUBSCRIBE_PORT | 4443 |  |  |
| SE_NODE_SESSION_TIMEOUT | 300 |  | --session-timeout |
| SE_NODE_ENABLE_MANAGED_DOWNLOADS |  |  | --enable-managed-downloads |
| SE_NODE_ENABLE_CDP |  |  | --enable-cdp |
| SE_NODE_REGISTER_PERIOD | 120 |  | --register-period |
| SE_NODE_REGISTER_CYCLE | 10 |  | --register-cycle |
| SE_NODE_HEARTBEAT_PERIOD | 30 |  | --heartbeat-period |
| SE_REGISTRATION_SECRET |  |  | --registration-secret |
| SE_BROWSER_LEFTOVERS_PROCESSES_SECS | 7200 |  |  |
| SE_BROWSER_LEFTOVERS_TEMPFILES_DAYS | 1 |  |  |
| SE_BROWSER_LEFTOVERS_INTERVAL_SECS | 3600 |  |  |
| SE_DISABLE_UI |  |  | --disable-ui |
| SE_REJECT_UNSUPPORTED_CAPS | false |  | --reject-unsupported-caps |
| SE_NEW_SESSION_THREAD_POOL_SIZE |  |  | --newsession-threadpool-size |
| SE_SESSION_REQUEST_TIMEOUT | 300 |  | --session-request-timeout |
| SE_SESSION_RETRY_INTERVAL | 15 |  | --session-retry-interval |
| SE_HEALTHCHECK_INTERVAL | 120 |  | --healthcheck-interval |
| SE_RELAX_CHECKS | true |  | --relax-checks |
| SE_SESSION_QUEUE_HOST |  |  | --sessionqueue-host |
| SE_SESSION_QUEUE_PORT | 5559 |  | --sessionqueue-port |
| SE_VIDEO_FOLDER |  |  |  |
| SE_LOG_LISTEN_GRAPHQL |  |  |  |
| SE_NODE_PRESTOP_WAIT_STRATEGY |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_DATASTORE | false |  |  |
| SE_SESSIONS_MAP_HOST |  |  | --sessions-host |
| SE_SESSIONS_MAP_PORT | 5556 |  | --sessions-port |
| SE_DISTRIBUTOR_HOST |  |  |  |
| SE_DISTRIBUTOR_PORT | 5553 |  |  |
| SE_GRID_URL |  |  | --grid-url |
| SE_NODE_DOCKER_CONFIG_FILENAME | docker.toml |  |  |
| SE_NODE_GRACEFUL_SHUTDOWN |  |  |  |
| SE_VIDEO_CONTAINER_NAME |  |  |  |
| SE_RECORD_VIDEO | true |  |  |
| SE_ENABLE_BROWSER_LEFTOVERS_CLEANUP | false |  |  |
| SE_NODE_MAX_SESSIONS | 1 |  |  |
| SE_NODE_OVERRIDE_MAX_SESSIONS | false |  |  |
| SE_OFFLINE | true | Selenium Manager offline mode, use the browser and driver pre-configured in the image |  |
| SE_NODE_BROWSER_VERSION | stable | Overwrite the default browserVersion in Node stereotype |  |
| SE_NODE_PLATFORM_NAME | Linux | Overwrite the default platformName in Node stereotype |  |
| SE_SUPERVISORD_LOG_LEVEL | info |  |  |
| SE_SUPERVISORD_CHILD_LOG_DIR | /tmp |  |  |
| SE_SUPERVISORD_LOG_FILE | /tmp/supervisord.log |  |  |
| SE_SUPERVISORD_AUTO_RESTART | true |  |  |
| SE_SUPERVISORD_START_RETRIES | 5 |  |  |
| SE_RECORD_AUDIO | false | Flag to enable recording the audio source (default is Pulse Audio input) |  |
| SE_AUDIO_SOURCE | -f pulse -ac 2 -i default | FFmpeg arguments to record the audio source |  |
| SE_BROWSER_BINARY_LOCATION |  |  |  |
| SE_NODE_BROWSER_NAME |  |  |  |
| SE_NODE_CONTAINER_NAME |  |  |  |
| SE_NODE_HOST |  |  |  |
| SE_NODE_RELAY_BROWSER_NAME |  |  |  |
| SE_NODE_RELAY_MAX_SESSIONS |  |  |  |
| SE_NODE_RELAY_PLATFORM_NAME |  |  |  |
| SE_NODE_RELAY_PLATFORM_VERSION |  |  |  |
| SE_NODE_RELAY_PROTOCOL_VERSION |  |  |  |
| SE_NODE_RELAY_STATUS_ENDPOINT |  |  |  |
| SE_NODE_RELAY_URL |  |  |  |
| SE_NODE_STEREOTYPE |  | Capabilities in JSON string to overwrite the default Node stereotype |  |
| SE_NODE_STEREOTYPE_EXTRA |  | Extra capabilities in JSON string that wants to merge to the default Node stereotype |  |
| SE_SESSIONS_MAP_EXTERNAL_HOSTNAME |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_IMPLEMENTATION |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_JDBC_PASSWORD |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_JDBC_URL |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_JDBC_USER |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_PORT |  |  |  |
| SE_SESSIONS_MAP_EXTERNAL_SCHEME |  |  |  |
| SE_NODE_RELAY_STEREOTYPE |  | Capabilities in JSON string to overwrite the default Node relay stereotype |  |
| SE_NODE_RELAY_STEREOTYPE_EXTRA |  | Extra capabilities in JSON string that wants to merge to the default Node relay stereotype |  |
| SE_NODE_REGISTER_SHUTDOWN_ON_FAILURE | true | If this flag is enabled, the Node will shut down after the register period is completed. This is useful for container environments to restart and register again. If restarted multiple times, the Node container status will be CrashLoopBackOff | --register-shutdown-on-failure |
| SE_NODE_RELAY_BROWSER_VERSION |  |  |  |
| SE_NODE_RELAY_ONLY | true |  |  |
| SE_EXTRA_LIBS | | Extra jars to add to the classpath | --ext |
