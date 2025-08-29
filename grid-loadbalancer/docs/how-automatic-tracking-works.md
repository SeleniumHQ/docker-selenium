# How Automatic Client Session Mapping Works

## Overview

The Go Load Balancer provides **completely automatic** client session mapping to Grid instances without requiring any changes to existing WebDriver clients. Here's exactly how it works:

## 1. Automatic Session Creation Tracking

When a client creates a new session (`POST /session`):

```
Client → Load Balancer → Best Grid Instance
   ↓
Load Balancer automatically:
1. Selects best available Grid instance
2. Forwards session creation request
3. Parses response to extract session ID
4. Stores mapping: SessionID → GridInstanceID
5. Optionally generates client UUID for recovery
```

**Code Implementation:**
```go
// In proxy/router.go - handleSessionCreation()
if resp.StatusCode == http.StatusOK {
    var sessionResp SessionCreationResponse
    if err := json.Unmarshal(respBody, &sessionResp); err == nil {
        sessionID := sessionResp.Value.SessionID
        
        // AUTOMATIC registration - no client action needed
        r.sessionRegistry.RegisterSession(
            sessionID, 
            instance.ID, 
            clientUUID, 
            userAgent, 
            clientIP,
        )
    }
}
```

## 2. Automatic Session Routing

For all subsequent requests with session IDs (`/session/{sessionId}/...`):

```
Client Request → Load Balancer
                      ↓
              Extract SessionID from URL
                      ↓
              Look up Grid Instance
                      ↓
              Route to Correct Instance
```

**Code Implementation:**
```go
// In proxy/router.go - ServeHTTP()
sessionID := r.extractSessionID(req.URL.Path)
if sessionID != "" {
    // AUTOMATIC lookup - no client configuration needed
    gridInstanceID, err := r.sessionRegistry.GetGridInstance(sessionID)
    if err == nil {
        r.routeToInstance(w, req, gridInstanceID, start)
    }
}
```

## 3. Automatic Session Discovery

The load balancer continuously discovers sessions from Grid instances:

```go
// Runs every 2 minutes automatically
func (r *Registry) DiscoverSessionsFromGrids(gridManager GridManager) {
    instances := gridManager.GetHealthyInstances()
    
    for _, instance := range instances {
        // Query Grid instance for active sessions
        sessions, err := r.queryGridInstanceSessions(instance.URL)
        
        // Register any unknown sessions automatically
        for _, sessionID := range sessions {
            if _, err := r.GetGridInstance(sessionID); err != nil {
                r.RegisterSession(sessionID, instance.ID, "", "", "")
            }
        }
    }
}
```

## 4. Automatic Session Monitoring

The load balancer monitors session health every 30 seconds:

```go
// Automatic session verification
func (r *Registry) monitorSessionStates(gridManager GridManager) {
    for _, sessionInfo := range sessions {
        if r.verifySessionExists(sessionInfo, gridManager) {
            r.updateLastAccessed(sessionInfo.SessionID)
        } else {
            // AUTOMATIC cleanup of stale sessions
            r.RemoveSession(sessionInfo.SessionID)
        }
    }
}
```

## 5. Intelligent Retry Strategy

The load balancer uses an intelligent retry strategy that adapts based on available Grid instances:

### Strategy 1: MaxRetries ≤ GridInstance Count
When MaxRetries is less than or equal to the number of healthy Grid instances, try each instance once:

```go
// Example: 3 MaxRetries, 5 Grid instances
// Retry plan: [grid-1, grid-2, grid-3] - try different instances
func (r *Router) buildRetryPlanOneByOne(instances []*grid.InstanceStatus, preferredInstanceID string, maxRetries int) []string {
    // Try preferred instance first, then others until maxRetries reached
}
```

### Strategy 2: MaxRetries > GridInstance Count  
When MaxRetries exceeds the number of Grid instances, cycle through all instances multiple times:

```go
// Example: 7 MaxRetries, 3 Grid instances
// Retry plan: [grid-1, grid-2, grid-3, grid-1, grid-2, grid-3, grid-1]
func (r *Router) buildRetryPlanWithCycles(instances []*grid.InstanceStatus, preferredInstanceID string, maxRetries int) []string {
    // Cycle through all instances until maxRetries reached
}
```

### Automatic Implementation
```go
func (r *Router) executeWithIntelligentRetry(w http.ResponseWriter, req *http.Request, preferredInstanceID string, start time.Time) bool {
    healthyInstances := r.gridManager.GetHealthyInstances()
    maxRetries := r.config.LoadBalancer.MaxRetries
    numInstances := len(healthyInstances)

    var retryPlan []string
    if maxRetries <= numInstances {
        retryPlan = r.buildRetryPlanOneByOne(healthyInstances, preferredInstanceID, maxRetries)
    } else {
        retryPlan = r.buildRetryPlanWithCycles(healthyInstances, preferredInstanceID, maxRetries)
    }
    
    // Execute retry plan with intelligent instance selection
}
```

## 6. Automatic Failover Handling

When a Grid instance fails, the load balancer automatically handles failover:

```go
func (r *Router) handleFailover(w http.ResponseWriter, req *http.Request, sessionID, failedInstanceID string, start time.Time) {
    healthyInstances := r.gridManager.GetHealthyInstances()
    
    for _, instance := range healthyInstances {
        // Check if session exists on another instance
        if r.sessionExistsOnInstance(sessionID, instance.URL) {
            // AUTOMATIC session migration
            r.sessionRegistry.RegisterSession(sessionID, instance.ID, ...)
            r.routeToInstance(w, req, instance.ID, start)
            return
        }
    }
}
```

## Client Usage - Zero Configuration Required

Clients use standard WebDriver code with **no modifications**:

```python
# Standard WebDriver usage - completely automatic tracking
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',  # Load balancer URL
    desired_capabilities=DesiredCapabilities.CHROME
)

# All operations automatically routed to correct Grid instance
driver.get("https://example.com")
driver.find_element_by_tag_name("body")
driver.quit()  # Automatically cleaned up
```

## What Happens Behind the Scenes

### Session Creation Flow
1. **Client** sends `POST /session` to load balancer
2. **Load Balancer** selects best Grid instance (grid-1)
3. **Load Balancer** forwards request to grid-1
4. **Grid-1** creates session and returns session ID (abc123)
5. **Load Balancer** automatically stores: `abc123 → grid-1`
6. **Load Balancer** returns response to client

### Session Operation Flow
1. **Client** sends `GET /session/abc123/title` to load balancer
2. **Load Balancer** extracts session ID: `abc123`
3. **Load Balancer** looks up mapping: `abc123 → grid-1`
4. **Load Balancer** routes request to grid-1
5. **Grid-1** processes request and returns response
6. **Load Balancer** forwards response to client

### Connection Recovery Flow
1. **Client** loses connection and reconnects
2. **Client** sends request with same session ID: `abc123`
3. **Load Balancer** automatically routes to correct instance (grid-1)
4. **Session continues seamlessly**

### Failover Flow
1. **Grid-1** becomes unhealthy
2. **Load Balancer** detects failure during health check
3. **Client** sends request for session `abc123`
4. **Load Balancer** detects grid-1 is unhealthy
5. **Load Balancer** searches other instances for session `abc123`
6. **Load Balancer** finds session on grid-2 (if migrated)
7. **Load Balancer** updates mapping: `abc123 → grid-2`
8. **Request routed to grid-2 automatically**

## Automatic Features Summary

| Feature | How It Works | Client Action Required |
|---------|--------------|----------------------|
| **Session Creation** | Load balancer selects best instance and stores mapping | None |
| **Session Routing** | Extracts session ID from URL and routes to correct instance | None |
| **Session Discovery** | Periodically queries Grid instances for active sessions | None |
| **Session Monitoring** | Verifies sessions exist and cleans up stale ones | None |
| **Connection Recovery** | Uses session ID to route reconnections correctly | None |
| **Failover Handling** | Detects failures and migrates sessions automatically | None |
| **Session Cleanup** | Removes expired sessions from tracking | None |

## Configuration for Automatic Tracking

```yaml
# config.yaml - All automatic features enabled by default
loadbalancer:
  port: 4444
  health_check_interval: 30s    # How often to check Grid health
  session_timeout: 300s         # When to clean up sessions
  enable_metrics: true          # Track automatic operations

grid_instances:
  - id: "grid-1"
    url: "http://localhost:4445"
    enabled: true
  - id: "grid-2"
    url: "http://localhost:4446"
    enabled: true

redis:
  enabled: true                 # Persist mappings across restarts
  host: "localhost"
  port: 6379
  key_ttl: 3600                # Session mapping expiration

monitoring:
  enabled: true                 # Monitor automatic operations
  metrics_port: 9090
```

## Monitoring Automatic Operations

The load balancer provides metrics and endpoints to monitor automatic tracking:

### Metrics (Prometheus format)
- `loadbalancer_sessions_created_total` - Sessions automatically tracked
- `loadbalancer_sessions_discovered_total` - Sessions found via discovery
- `loadbalancer_sessions_migrated_total` - Sessions moved during failover
- `loadbalancer_connection_recoveries_total` - Automatic recoveries

### REST Endpoints
- `GET /lb/health` - Load balancer and Grid instance health
- `GET /lb/sessions` - Current active session count
- `GET /lb/instances` - Grid instance status and distribution

### Logs
```
2024-01-15 10:30:15 Session abc123 created on grid instance grid-1 (client UUID: uuid-456)
2024-01-15 10:30:45 Routed GET /session/abc123/title to grid-1 in 45ms
2024-01-15 10:31:00 Discovered and registered session def789 on grid-2
2024-01-15 10:31:30 Automatically migrated session abc123 from grid-1 to grid-2
2024-01-15 10:32:00 Automatically removed stale session: xyz999
```

## Benefits of Automatic Tracking

1. **Zero Client Changes**: Existing WebDriver code works without modification
2. **Transparent Operation**: Clients don't need to know about multiple Grid instances
3. **Automatic Recovery**: Handles connection issues and failover seamlessly
4. **Self-Healing**: Discovers and cleans up sessions automatically
5. **High Availability**: Continues working even if some Grid instances fail
6. **Scalability**: Add/remove Grid instances without client reconfiguration
7. **Observability**: Comprehensive monitoring of all automatic operations

The automatic tracking system ensures that clients get a seamless, highly available Selenium Grid experience without any additional complexity or configuration requirements.
