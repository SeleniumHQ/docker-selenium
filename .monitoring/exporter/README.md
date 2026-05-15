# Selenium Grid Prometheus Exporter

Exports Selenium Grid metrics to Prometheus by querying the Grid's GraphQL endpoint.
Each scrape issues a single GraphQL request covering grid summary, node stereotypes, active sessions, and the session queue.

## Requirements

- Go 1.26+
- A running Selenium Grid 4+ instance with the GraphQL endpoint accessible

## Build

```bash
# from repo root
make build_exporter

# binary lands at
bin/selenium-grid-exporter
```

Or build directly:

```bash
cd .monitoring/exporter
go build -ldflags="-s -w" -o ../../bin/selenium-grid-exporter .
```

## Run

```bash
bin/selenium-grid-exporter \
  -grid-url        http://selenium-hub:4444/graphql \
  -listen-address  :9615 \
  -scrape-timeout  10s \
  -metrics-path    /metrics \
  -grid-timezone   Asia/Ho_Chi_Minh \
  -retain-stopped  5m
```

### Flags

| Flag | Default | Description |
|---|---|---|
| `-grid-url` | `$SE_SERVER_PROTOCOL://localhost:$SE_ROUTER_PORT/$SE_SUB_PATH/graphql` | Selenium Grid GraphQL endpoint; auto-constructed from Hub/Router env vars |
| `-listen-address` | `:9615` | Address the exporter listens on |
| `-scrape-timeout` | `10s` | Per-scrape HTTP timeout for the GraphQL query |
| `-metrics-path` | `/metrics` | URL path to expose metrics on |
| `-grid-timezone` | `$TZ` or `UTC` | Timezone of the Grid JVM (for parsing `startTime`), e.g. `Asia/Ho_Chi_Minh` |
| `-retain-stopped` | `5m` | How long to keep `start/stop` metrics after a session ends |
| `-username` | `$SE_ROUTER_USERNAME` | Basic-auth username for the Grid endpoint |
| `-password` | `$SE_ROUTER_PASSWORD` | Basic-auth password for the Grid endpoint |

## Deployment

### Docker Compose

The exporter runs as a standalone container querying the Hub or Router over the network:

```yaml
selenium-exporter:
  image: selenium/selenium-grid-exporter:latest
  environment:
    SE_ROUTER_USERNAME: admin
    SE_ROUTER_PASSWORD: secret
  command:
    - -grid-url=http://selenium-hub:4444/graphql
    - -grid-timezone=UTC
  ports:
    - "9615:9615"
```

### Kubernetes (Helm chart)

When `monitoring.enabled: true` is set, the exporter binary is embedded in the Hub/Router image and started automatically on port `9615` alongside the Selenium server process. A `ServiceMonitor` is created to let Prometheus Operator discover and scrape it.

## Prometheus configuration

### Static scrape (Docker Compose)

```yaml
scrape_configs:
  - job_name: selenium_grid
    static_configs:
      - targets: ["localhost:9615"]
```

### Prometheus Operator (Kubernetes)

Enable the ServiceMonitor via Helm values:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

## Metrics reference

### Exporter health

| Metric | Type | Description |
|---|---|---|
| `selenium_grid_scrape_success` | Gauge | `1` if the last GraphQL scrape succeeded, `0` if it failed (network error, auth error, etc.) |
| `selenium_grid_scrape_duration_seconds` | Gauge | Duration of the last GraphQL scrape in seconds |

### Grid summary

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_info` | Gauge | `version` | Always `1`; exposes the Grid version string as a label |
| `selenium_grid_total_slots` | Gauge | — | Total slots across all nodes |
| `selenium_grid_node_count` | Gauge | — | Number of registered nodes |
| `selenium_grid_max_sessions` | Gauge | — | Maximum concurrent sessions across all nodes |
| `selenium_grid_session_count` | Gauge | — | Number of currently active sessions |
| `selenium_grid_session_queue_size` | Gauge | — | Session requests waiting in the queue |

### Node

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_node_status` | Gauge | `node_id`, `uri`, `version`, `os_name`, `os_arch`, `os_version` | Node availability: `1`=UP, `0.5`=DRAINING, `0`=DOWN |
| `selenium_grid_node_status_duration_seconds` | Gauge | `node_id`, `status` | Seconds the node has continuously been in its current status |
| `selenium_grid_node_max_sessions` | Gauge | `node_id` | Max concurrent sessions for the node |
| `selenium_grid_node_slot_count` | Gauge | `node_id` | Total slot count for the node |
| `selenium_grid_node_session_count` | Gauge | `node_id` | Active session count for the node |

### Node stereotypes

Slots available per node broken down by the capability combination each slot is configured for.

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_node_stereotype_slots_total` | Gauge | `node_id`, `browser_name`, `browser_version`, `platform_name` | Slot count per stereotype capability |

**Example** — a node registered with two Chrome slots and one Firefox slot:

```
selenium_grid_node_stereotype_slots_total{node_id="abc",browser_name="chrome",browser_version="124",platform_name="linux"} 2
selenium_grid_node_stereotype_slots_total{node_id="abc",browser_name="firefox",browser_version="125",platform_name="linux"} 1
```

### Active sessions

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_sessions_active` | Gauge | `browser_name`, `browser_version`, `platform_name` | Active session count aggregated by capability |
| `selenium_grid_session_duration_seconds` | Gauge | `session_id`, `node_id`, `browser_name`, `browser_version`, `platform_name`, `test_name`, `container_name` | Duration of each individual active session |

### Session lifecycle (start / stop time)

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_session_start_seconds` | Gauge | `session_id`, `node_id`, `browser_name`, `browser_version`, `platform_name`, `test_name`, `container_name` | Unix timestamp when the session started (parsed from Grid's `startTime` field) |
| `selenium_grid_session_stop_seconds` | Gauge | `session_id`, `node_id`, `browser_name`, `browser_version`, `platform_name`, `test_name`, `container_name` | Unix timestamp when the session ended (set on the first scrape after termination) |
| `selenium_grid_sessions_completed_total` | Counter | — | Total sessions ended since the exporter started (resets on exporter restart) |

**How it works:**
- `session_start_seconds` is available for every active session on every scrape.
- `session_stop_seconds` is set when the exporter detects a session has disappeared from the Grid response. The metric is retained for `-retain-stopped` (default `5m`) to ensure Prometheus scrapes it at least once.
- `sessions_completed_total` increments each time a session disappears, enabling `rate()` and `increase()` throughput calculations.
- The `-grid-timezone` flag must match the JVM timezone of the Grid server, because Grid formats `startTime` as a local-time string without offset.

### Session queue

Requests waiting in the new-session queue, aggregated by desired capability.

| Metric | Type | Labels | Description |
|---|---|---|---|
| `selenium_grid_session_queue_requests` | Gauge | `browser_name`, `browser_version`, `platform_name` | Queued request count per desired capability |

## Example output

```
# HELP selenium_grid_total_slots Total number of slots across all nodes.
# TYPE selenium_grid_total_slots gauge
selenium_grid_total_slots 8

# HELP selenium_grid_node_count Number of registered nodes.
# TYPE selenium_grid_node_count gauge
selenium_grid_node_count 2

# HELP selenium_grid_session_count Number of active sessions grid-wide.
# TYPE selenium_grid_session_count gauge
selenium_grid_session_count 3

# HELP selenium_grid_session_queue_size Number of session requests waiting in the queue.
# TYPE selenium_grid_session_queue_size gauge
selenium_grid_session_queue_size 1

# HELP selenium_grid_node_status Node availability: 1=UP, 0.5=DRAINING, 0=DOWN.
# TYPE selenium_grid_node_status gauge
selenium_grid_node_status{node_id="abc",uri="http://node1:5555",version="4.20.0",os_name="Linux",os_arch="amd64",os_version="5.15"} 1
selenium_grid_node_status{node_id="def",uri="http://node2:5555",version="4.20.0",os_name="Linux",os_arch="amd64",os_version="5.15"} 0.5

# HELP selenium_grid_node_stereotype_slots_total Slots available per node stereotype (browser/version/platform combination).
# TYPE selenium_grid_node_stereotype_slots_total gauge
selenium_grid_node_stereotype_slots_total{node_id="abc",browser_name="chrome",browser_version="124",platform_name="linux"} 4
selenium_grid_node_stereotype_slots_total{node_id="def",browser_name="firefox",browser_version="125",platform_name="linux"} 4

# HELP selenium_grid_sessions_active Number of active sessions by capability.
# TYPE selenium_grid_sessions_active gauge
selenium_grid_sessions_active{browser_name="chrome",browser_version="124",platform_name="linux"} 2
selenium_grid_sessions_active{browser_name="firefox",browser_version="125",platform_name="linux"} 1

# HELP selenium_grid_session_duration_seconds Duration of an active session in seconds.
# TYPE selenium_grid_session_duration_seconds gauge
selenium_grid_session_duration_seconds{session_id="s1",node_id="abc",browser_name="chrome",browser_version="124",platform_name="linux"} 42.3

# HELP selenium_grid_session_queue_requests Number of queued session requests by desired capability.
# TYPE selenium_grid_session_queue_requests gauge
selenium_grid_session_queue_requests{browser_name="chrome",browser_version="124",platform_name="linux"} 1
```

## Useful queries

**Sessions waiting vs capacity:**
```promql
selenium_grid_session_queue_size / selenium_grid_total_slots
```

**Slot utilisation per browser:**
```promql
selenium_grid_sessions_active
  / on(browser_name, browser_version, platform_name)
  sum by(browser_name, browser_version, platform_name) (selenium_grid_node_stereotype_slots_total)
```

**Nodes not UP:**
```promql
selenium_grid_node_status < 1
```

**Nodes that have been DRAINING for more than 2 minutes:**
```promql
selenium_grid_node_status_duration_seconds{status="DRAINING"} > 120
```

**How long each node has been in its current status:**
```promql
selenium_grid_node_status_duration_seconds
```

**Current duration of all active sessions:**
```promql
selenium_grid_session_duration_seconds
```

**All sessions for a specific test:**
```promql
selenium_grid_session_duration_seconds{test_name="my-login-test"}
```

**All sessions running in a specific container:**
```promql
selenium_grid_session_duration_seconds{container_name="node-chrome-1"}
```

**Start time of a specific session:**
```promql
selenium_grid_session_start_seconds{session_id="<id>"}
```

**Stop time of a specific session (available for `-retain-stopped` after it ends):**
```promql
selenium_grid_session_stop_seconds{session_id="<id>"}
```

**Total wall-clock duration of a completed session (start → stop):**
```promql
selenium_grid_session_stop_seconds{session_id="<id>"}
  - selenium_grid_session_start_seconds{session_id="<id>"}
```

**All sessions that ran longer than 10 minutes:**
```promql
(selenium_grid_session_stop_seconds - selenium_grid_session_start_seconds) > 600
```

**Alert: exporter cannot reach the Grid:**
```promql
selenium_grid_scrape_success == 0
```

**Session throughput (completions per second, 5-minute window):**
```promql
rate(selenium_grid_sessions_completed_total[5m])
```

**Sessions completed in the last hour:**
```promql
increase(selenium_grid_sessions_completed_total[1h])
```

**Grid version:**
```promql
selenium_grid_info
```
