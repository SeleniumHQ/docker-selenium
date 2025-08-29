# Selenium Grid Load Balancer

A high-performance Go-based load balancer for Selenium Grid that provides **automatic session tracking**, intelligent retry strategies, and seamless failover across multiple Grid instances - all completely transparent to WebDriver clients.

## ✨ Key Features

- **🎯 Automatic Session Tracking**: Zero-configuration session mapping to Grid instances
- **🔄 Intelligent Retry Strategy**: Adapts retry behavior based on available Grid instance count
- **🚀 Session Affinity**: Routes requests to the correct Grid instance where the session exists
- **🔗 Connection Recovery**: Handles connection interruptions, timeouts, and reconnections
- **💚 Health Checking**: Monitors Grid instance availability with automatic failover
- **🆔 Enhanced Session Management**: Client UUID support for advanced session tracking
- **📊 Redis Backend**: Optional Redis storage for session persistence across restarts
- **📈 Metrics & Monitoring**: Comprehensive Prometheus metrics for observability
- **⚡ High Availability**: Supports multiple Grid instances with priority-based routing
- **🔍 Automatic Session Discovery**: Periodically discovers and registers sessions from Grid instances
- **🛡️ Automatic Failover**: Seamless session migration during Grid instance failures

## Architecture

```
Client (with UUID) → Load Balancer → Grid Instance 1 (Router, Distributor, Nodes)
                                  → Grid Instance 2 (Router, Distributor, Nodes)
                                  → Grid Instance 3 (Router, Distributor, Nodes)
```

The load balancer acts as a bridge between clients and multiple Grid instances, ensuring that:
1. **Automatic Session Creation**: New sessions are created on the best available Grid instance
2. **Intelligent Session Routing**: Existing session requests are routed to the correct Grid instance
3. **Smart Retry Strategy**: Connection failures are handled with intelligent retry across instances
4. **Session State Preservation**: Session state is preserved across connection interruptions
5. **Zero Client Configuration**: Standard WebDriver code works without any modifications

## Quick Start

### 1. Build the Load Balancer

```bash
cd go-grid-loadbalancer
go mod tidy
go build -o selenium-grid-lb main.go
```

### 2. Configure Grid Instances

Create a `config.yaml` file:

```yaml
loadbalancer:
  port: 4444
  health_check_interval: 30s
  session_timeout: 300s
  max_retries: 3
  retry_interval: 5s
  enable_metrics: true

grid_instances:
  - id: "grid-1"
    url: "http://localhost:4445"
    priority: 1
    weight: 100
    enabled: true
  - id: "grid-2"
    url: "http://localhost:4446"
    priority: 1
    weight: 100
    enabled: true

redis:
  enabled: true
  host: "localhost"
  port: 6379
  password: ""
  db: 0
  key_ttl: 3600

monitoring:
  enabled: true
  metrics_port: 9090
```

### 3. Start Grid Instances

Start multiple Selenium Grid instances on different ports:

```bash
# Grid Instance 1
java -jar selenium-server-4.x.x.jar hub --port 4445

# Grid Instance 2  
java -jar selenium-server-4.x.x.jar hub --port 4446

# Add nodes to each grid instance
java -jar selenium-server-4.x.x.jar node --hub http://localhost:4445/grid/register
java -jar selenium-server-4.x.x.jar node --hub http://localhost:4446/grid/register
```

### 4. Start the Load Balancer

```bash
./selenium-grid-lb -config config.yaml
```

### 5. Use with WebDriver

The load balancer is now ready to accept WebDriver connections on port 4444:

```python
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

# The load balancer will automatically route to the best Grid instance
driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    desired_capabilities=DesiredCapabilities.CHROME
)

# All subsequent requests will be routed to the same Grid instance
driver.get("https://example.com")
driver.quit()
```

## 🔄 Intelligent Retry Strategy

The load balancer implements an **intelligent retry strategy** that adapts based on the number of available Grid instances:

### Strategy 1: MaxRetries ≤ GridInstance Count
When `MaxRetries` is less than or equal to the number of healthy Grid instances, each instance is tried once:

```yaml
# Example: 3 MaxRetries, 5 Grid instances
# Retry sequence: [preferred-instance, grid-2, grid-3]
loadbalancer:
  max_retries: 3  # Try 3 different instances
```

### Strategy 2: MaxRetries > GridInstance Count  
When `MaxRetries` exceeds the number of Grid instances, the load balancer cycles through all instances:

```yaml
# Example: 7 MaxRetries, 3 Grid instances  
# Retry sequence: [grid-1, grid-2, grid-3, grid-1, grid-2, grid-3, grid-1]
loadbalancer:
  max_retries: 7  # Cycle through instances multiple times
```

### Benefits
- **Maximized Success Rate**: Tries different instances instead of repeatedly failing on the same one
- **Adaptive Behavior**: Automatically adjusts to available Grid instance count
- **Predictable Performance**: Clear retry patterns for monitoring and debugging
- **Resource Efficiency**: Avoids unnecessary retries on known-failed instances

## 🎯 Automatic Session Tracking & Connection Recovery

### How Automatic Session Tracking Works

1. **Automatic Session Creation**: When a new session is created, the load balancer:
   - Selects the best available Grid instance based on health and priority
   - Forwards the session creation request
   - **Automatically registers** the session ID → Grid instance mapping
   - Optionally generates and tracks a client UUID
   - **No client configuration required**

2. **Intelligent Session Routing**: For subsequent requests:
   - Extracts session ID from the URL path (`/session/{sessionId}/...`)
   - Looks up the Grid instance for that session
   - Routes the request to the correct Grid instance
   - **Completely transparent to the client**

3. **Automatic Session Discovery**: The load balancer continuously:
   - Queries Grid instances for active sessions (every 2 minutes)
   - Registers any unknown sessions automatically
   - Cleans up stale sessions (every 30 seconds)

4. **Connection Recovery**: If a connection is interrupted:
   - Client can include `X-Client-UUID` header for enhanced session recovery
   - Load balancer attempts to map client UUID back to session ID
   - Routes reconnection to the correct Grid instance
   - **Works with standard WebDriver reconnection patterns**

### Client UUID Enhancement

To enable enhanced session tracking, clients can include a UUID header:

```python
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
import uuid

# Generate a unique client UUID
client_uuid = str(uuid.uuid4())

# Add custom headers (requires custom WebDriver implementation)
capabilities = DesiredCapabilities.CHROME.copy()
capabilities['se:options'] = {
    'headers': {
        'X-Client-UUID': client_uuid
    }
}

driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    desired_capabilities=capabilities
)
```

## Monitoring & Metrics

### Health Endpoints

- `GET /status` - Load balancer status and Grid instance health
- `GET /lb/health` - Health check endpoint
- `GET /lb/sessions` - Active session information
- `GET /lb/instances` - Grid instance status

### Prometheus Metrics

When monitoring is enabled, metrics are available at `http://localhost:9090/metrics`:

**Core Metrics:**
- `loadbalancer_requests_total` - Total requests processed
- `loadbalancer_request_duration_seconds` - Request duration histogram
- `loadbalancer_active_sessions` - Number of active sessions
- `loadbalancer_sessions_created_total` - Sessions created per Grid instance
- `loadbalancer_grid_instances_healthy` - Grid instance health status

**Enhanced Tracking Metrics:**
- `loadbalancer_sessions_discovered_total` - Sessions found via automatic discovery
- `loadbalancer_sessions_migrated_total` - Sessions moved during failover
- `loadbalancer_connection_recoveries_total` - Connection recovery events
- `loadbalancer_retry_attempts_total` - Retry attempts per strategy
- `loadbalancer_failover_events_total` - Automatic failover events

## Configuration Reference

### Load Balancer Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `port` | Load balancer port | 4444 |
| `health_check_interval` | Health check frequency | 30s |
| `session_timeout` | Session expiration time | 300s |
| `max_retries` | **Intelligent retry attempts** | 3 |
| `retry_interval` | Retry delay between attempts | 5s |
| `enable_metrics` | Enable comprehensive metrics | false |

**Note**: `max_retries` now uses intelligent retry strategy:
- If `max_retries ≤ Grid instances`: Try each instance once
- If `max_retries > Grid instances`: Cycle through instances multiple times

### Grid Instance Settings

| Setting | Description | Required |
|---------|-------------|----------|
| `id` | Unique instance identifier | Yes |
| `url` | Grid instance URL | Yes |
| `priority` | Priority (lower = higher priority) | No |
| `weight` | Load balancing weight | No |
| `enabled` | Enable/disable instance | No |
| `username` | **Basic auth username** (optional) | No |
| `password` | **Basic auth password** (optional) | No |

**Basic Authentication Support**: Grid instances can be secured with HTTP Basic Authentication. Simply add `username` and `password` fields to the grid instance configuration:

```yaml
grid_instances:
  - id: "secure-grid"
    url: "https://secure-grid.example.com:4444"
    username: "admin"
    password: "secret123"
    enabled: true
```

The load balancer will automatically include the authentication headers when:
- Making health check requests to the Grid instance
- Forwarding WebDriver requests through the proxy
- Performing session discovery and monitoring

## 🎯 Advanced Load Balancing Strategies

The load balancer supports multiple advanced strategies for distributing new sessions across Grid instances:

### 1. Weighted Round Robin (`weighted_round_robin`)

Distributes sessions based on instance weights and priorities:
- **Weight-based distribution**: Higher weight instances receive more sessions proportionally
- **Priority consideration**: Uses priority for tie-breaking and ordering
- **Session counting**: Tracks active sessions per instance for accurate distribution
- **Ideal for**: Heterogeneous Grid instances with different capacities

**Configuration Example:**
```yaml
loadbalancer:
  strategy: "weighted_round_robin"

grid_instances:
  - id: "high-capacity"
    weight: 200    # Gets ~50% of sessions
    priority: 1
  - id: "medium-capacity"  
    weight: 120    # Gets ~30% of sessions
    priority: 1
  - id: "low-capacity"
    weight: 80     # Gets ~20% of sessions
    priority: 1
```

### 2. HA GEO (Active/Standby) (`ha_geo`)

Geographic high availability with active and standby roles:
- **Active instances**: Handle normal traffic within their region
- **Standby instances**: Provide failover capacity when active instances are unavailable
- **Priority-based**: Active instances (priority 1) are preferred over standby (priority 2+)
- **Geographic failover**: Supports multi-region deployments with automatic failover
- **Role-aware**: Considers both `role` (active/standby) and `region` for routing decisions

**Configuration Example:**
```yaml
loadbalancer:
  strategy: "ha_geo"

grid_instances:
  # US East - Active
  - id: "us-east-1"
    priority: 1
    region: "us-east"
    role: "active"
  - id: "us-east-2"
    priority: 1
    region: "us-east" 
    role: "active"
  # US West - Standby
  - id: "us-west-1"
    priority: 2
    region: "us-west"
    role: "standby"
```

### 3. Greedy Strategy (`greedy`)

Assigns sessions to instances up to configured maximum limits:
- **Capacity-aware**: Fills instances to `max_sessions` before moving to next
- **Priority ordering**: Respects priority for instance selection order
- **Session limits**: Enforces maximum session limits per instance
- **Overflow handling**: Automatically moves to next available instance when limits reached
- **Ideal for**: Capacity-controlled environments with strict session limits

**Configuration Example:**
```yaml
loadbalancer:
  strategy: "greedy"

grid_instances:
  - id: "small-grid"
    priority: 1
    max_sessions: 5    # Fills first (5 sessions max)
  - id: "medium-grid"
    priority: 2  
    max_sessions: 10   # Fills second (10 sessions max)
  - id: "large-grid"
    priority: 3
    max_sessions: 20   # Fills third (20 sessions max)
```

### Strategy Selection

Choose the appropriate strategy based on your deployment needs:

| Strategy | Best For | Key Benefits |
|----------|----------|--------------|
| `weighted_round_robin` | Mixed capacity instances | Proportional load distribution, flexible weighting |
| `ha_geo` | Multi-region deployments | Geographic failover, active/standby roles |
| `greedy` | Capacity-controlled environments | Strict session limits, predictable filling |

### Extended Grid Instance Settings

For advanced load balancing strategies, additional configuration options are available:

| Setting | Description | Used By | Required |
|---------|-------------|---------|----------|
| `max_sessions` | Maximum concurrent sessions | `greedy` | For greedy strategy |
| `region` | Geographic region identifier | `ha_geo` | For HA GEO strategy |
| `role` | Instance role (active/standby) | `ha_geo` | For HA GEO strategy |
| `weight` | Load balancing weight | `weighted_round_robin` | For weighted strategy |

### Redis Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable Redis backend | false |
| `host` | Redis hostname | localhost |
| `port` | Redis port | 6379 |
| `password` | Redis password | "" |
| `db` | Redis database number | 0 |
| `key_ttl` | Key expiration time (seconds) | 3600 |

## 🚀 Deployment

### Quick Start with Docker Compose

The fastest way to get started is using the provided Docker Compose setup:

```bash
# Start complete stack (3 Grid instances + Load Balancer + Redis + Monitoring)
docker-compose up -d

# Check health
curl http://localhost:4444/lb/health

# Test with WebDriver (uses standard code - no changes needed!)
python examples/automatic-tracking-demo.py
```

### Docker Deployment

```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod tidy && go build -o selenium-grid-lb main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates curl
WORKDIR /app
COPY --from=builder /app/selenium-grid-lb .
COPY --from=builder /app/config.yaml .
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4444/lb/health || exit 1
CMD ["./selenium-grid-lb", "-config", "config.yaml"]
```

### Docker Compose

```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  selenium-grid-1:
    image: selenium/hub:4.15.0
    ports:
      - "4445:4444"
    environment:
      - HUB_HOST=0.0.0.0

  selenium-grid-2:
    image: selenium/hub:4.15.0
    ports:
      - "4446:4444"
    environment:
      - HUB_HOST=0.0.0.0

  load-balancer:
    build: .
    ports:
      - "4444:4444"
      - "9090:9090"
    depends_on:
      - redis
      - selenium-grid-1
      - selenium-grid-2
    volumes:
      - ./config.yaml:/root/config.yaml
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selenium-grid-lb
spec:
  replicas: 2
  selector:
    matchLabels:
      app: selenium-grid-lb
  template:
    metadata:
      labels:
        app: selenium-grid-lb
    spec:
      containers:
      - name: load-balancer
        image: selenium-grid-lb:latest
        ports:
        - containerPort: 4444
        - containerPort: 9090
        env:
        - name: CONFIG_FILE
          value: "/config/config.yaml"
        volumeMounts:
        - name: config
          mountPath: /config
      volumes:
      - name: config
        configMap:
          name: selenium-grid-lb-config
---
apiVersion: v1
kind: Service
metadata:
  name: selenium-grid-lb-service
spec:
  selector:
    app: selenium-grid-lb
  ports:
  - name: selenium
    port: 4444
    targetPort: 4444
  - name: metrics
    port: 9090
    targetPort: 9090
  type: LoadBalancer
```

## Troubleshooting

### Common Issues

1. **Session Not Found**: Check that the session ID is correctly extracted from the URL
2. **Grid Instance Unhealthy**: Verify Grid instance URLs and network connectivity
3. **Redis Connection Failed**: Ensure Redis is running and accessible
4. **High Response Times**: Check Grid instance capacity and add more instances

### Logging

The load balancer provides detailed logging for:
- Session creation and routing
- Health check results
- Connection recovery attempts
- Failover events

### Debug Mode

Enable debug logging by setting the log level:

```bash
export LOG_LEVEL=debug
./selenium-grid-lb -config config.yaml
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
