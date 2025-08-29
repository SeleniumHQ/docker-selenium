# Automatic Client Session Mapping to Grid Instances

## Overview

The Go Load Balancer automatically tracks client sessions and maps them to the correct Grid instances without requiring any client-side changes. This document explains how the automatic tracking works and how to enhance it further.

## Current Automatic Tracking Implementation

### 1. Session Creation Tracking

When a client creates a new session (`POST /session`), the load balancer automatically:

```go
// In proxy/router.go - handleSessionCreation()
func (r *Router) handleSessionCreation(w http.ResponseWriter, req *http.Request, clientUUID, clientIP, userAgent string) {
    // 1. Select best Grid instance
    instance, err := r.gridManager.GetBestInstance()
    
    // 2. Generate client UUID if not provided
    if clientUUID == "" {
        clientUUID = session.GenerateClientUUID()
    }
    
    // 3. Forward request to selected Grid instance
    // ... proxy logic ...
    
    // 4. Parse response and extract session ID
    var sessionResp SessionCreationResponse
    if err := json.Unmarshal(respBody, &sessionResp); err == nil && sessionResp.Value.SessionID != "" {
        sessionID := sessionResp.Value.SessionID
        
        // 5. AUTOMATICALLY register the mapping
        err := r.sessionRegistry.RegisterSession(sessionID, instance.ID, clientUUID, userAgent, clientIP)
        if err != nil {
            log.Printf("Failed to register session %s: %v", sessionID, err)
        } else {
            log.Printf("Session %s created on grid instance %s (client UUID: %s)", sessionID, instance.ID, clientUUID)
        }
    }
}
```

### 2. Session Routing Tracking

For all subsequent requests with session IDs in the URL (`/session/{sessionId}/...`):

```go
// In proxy/router.go - ServeHTTP()
func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    // 1. Extract session ID from URL automatically
    sessionID := r.extractSessionID(req.URL.Path)
    if sessionID == "" {
        // No session ID, route to best available instance
        r.routeToInstance(w, req, "", start)
        return
    }

    // 2. AUTOMATICALLY look up Grid instance for this session
    gridInstanceID, err := r.sessionRegistry.GetGridInstance(sessionID)
    if err != nil {
        // 3. Try connection recovery using client UUID
        clientUUID := req.Header.Get("X-Client-UUID")
        if clientUUID != "" {
            recoveredSessionID, err := r.sessionRegistry.GetSessionByClientUUID(clientUUID)
            if err == nil && recoveredSessionID == sessionID {
                log.Printf("Session %s recovered using client UUID %s", sessionID, clientUUID)
                gridInstanceID, err = r.sessionRegistry.GetGridInstance(sessionID)
            }
        }
    }

    // 4. Route to the correct Grid instance
    r.routeToInstance(w, req, gridInstanceID, start)
}
```

### 3. Session Cleanup Tracking

The load balancer automatically cleans up session mappings:

```go
// Automatic cleanup in main.go
go func() {
    ticker := time.NewTicker(5 * time.Minute)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            // AUTOMATICALLY cleanup expired sessions
            sessionRegistry.CleanupExpiredSessions(cfg.LoadBalancer.SessionTimeout)
            
            // Update metrics
            if cfg.Monitoring.Enabled {
                metrics.UpdateSessionMetrics(sessionRegistry.GetSessionCount())
            }
        }
    }
}()
```

## Enhanced Automatic Tracking Features

### 1. Session State Monitoring

Add automatic monitoring of session state by periodically checking Grid instances:

```go
// Enhanced session monitoring
func (r *Registry) StartSessionMonitoring(gridManager *grid.Manager, interval time.Duration) {
    ticker := time.NewTicker(interval)
    go func() {
        defer ticker.Stop()
        for {
            select {
            case <-ticker.C:
                r.monitorSessionStates(gridManager)
            }
        }
    }()
}

func (r *Registry) monitorSessionStates(gridManager *grid.Manager) {
    r.mu.RLock()
    sessions := make([]*SessionInfo, 0, len(r.sessions))
    for _, session := range r.sessions {
        sessions = append(sessions, session)
    }
    r.mu.RUnlock()

    for _, sessionInfo := range sessions {
        // Check if session still exists on the Grid instance
        if r.verifySessionExists(sessionInfo, gridManager) {
            r.updateLastAccessed(sessionInfo.SessionID)
        } else {
            // Session no longer exists, remove from registry
            r.RemoveSession(sessionInfo.SessionID)
            log.Printf("Automatically removed stale session: %s", sessionInfo.SessionID)
        }
    }
}
```

### 2. Grid Instance Session Discovery

Automatically discover sessions by querying Grid instances:

```go
// Discover sessions from Grid instances
func (r *Registry) DiscoverSessionsFromGrids(gridManager *grid.Manager) {
    instances := gridManager.GetHealthyInstances()
    
    for _, instance := range instances {
        sessions, err := r.queryGridInstanceSessions(instance.URL)
        if err != nil {
            log.Printf("Failed to query sessions from %s: %v", instance.ID, err)
            continue
        }
        
        // Register any unknown sessions
        for _, sessionID := range sessions {
            if _, err := r.GetGridInstance(sessionID); err != nil {
                // Session not in registry, add it
                r.RegisterSession(sessionID, instance.ID, "", "", "")
                log.Printf("Discovered and registered session %s on %s", sessionID, instance.ID)
            }
        }
    }
}

func (r *Registry) queryGridInstanceSessions(gridURL string) ([]string, error) {
    resp, err := http.Get(gridURL + "/status")
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var status struct {
        Value struct {
            Nodes []struct {
                Slots []struct {
                    Session *struct {
                        SessionID string `json:"sessionId"`
                    } `json:"session"`
                } `json:"slots"`
            } `json:"nodes"`
        } `json:"value"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
        return nil, err
    }
    
    var sessions []string
    for _, node := range status.Value.Nodes {
        for _, slot := range node.Slots {
            if slot.Session != nil && slot.Session.SessionID != "" {
                sessions = append(sessions, slot.Session.SessionID)
            }
        }
    }
    
    return sessions, nil
}
```

### 3. Automatic Failover Detection

Detect when a Grid instance fails and automatically handle session failover:

```go
// Enhanced failover with automatic session migration
func (r *Router) handleFailover(w http.ResponseWriter, req *http.Request, sessionID, failedInstanceID string, start time.Time) {
    log.Printf("Attempting automatic failover for session %s from failed instance %s", sessionID, failedInstanceID)

    // Try to find the session on other healthy Grid instances
    healthyInstances := r.gridManager.GetHealthyInstances()
    
    for _, instance := range healthyInstances {
        if instance.ID == failedInstanceID {
            continue // Skip the failed instance
        }
        
        // Check if session exists on this instance
        if r.sessionExistsOnInstance(sessionID, instance.URL) {
            // Update the mapping to the new instance
            sessionInfo, err := r.sessionRegistry.GetSessionInfo(sessionID)
            if err == nil {
                r.sessionRegistry.RegisterSession(
                    sessionID, 
                    instance.ID, 
                    sessionInfo.ClientUUID, 
                    sessionInfo.UserAgent, 
                    sessionInfo.ClientIP,
                )
                log.Printf("Automatically migrated session %s to instance %s", sessionID, instance.ID)
                
                // Route the request to the new instance
                r.routeToInstance(w, req, instance.ID, start)
                return
            }
        }
    }
    
    // If session not found on any instance, remove from registry
    r.sessionRegistry.RemoveSession(sessionID)
    http.Error(w, "Session not found after failover", http.StatusNotFound)
}
```

## Implementation Steps

### Step 1: Add Enhanced Session Monitoring

```go
// Add to main.go
func main() {
    // ... existing code ...
    
    // Start enhanced session monitoring
    go func() {
        ticker := time.NewTicker(2 * time.Minute)
        defer ticker.Stop()
        
        for {
            select {
            case <-ticker.C:
                // Monitor session states
                sessionRegistry.StartSessionMonitoring(gridManager, 30*time.Second)
                
                // Discover new sessions
                sessionRegistry.DiscoverSessionsFromGrids(gridManager)
            }
        }
    }()
    
    // ... rest of main function ...
}
```

### Step 2: Add Session Verification Methods

```go
// Add to session/registry.go
func (r *Registry) verifySessionExists(sessionInfo *SessionInfo, gridManager *grid.Manager) bool {
    instance, err := gridManager.GetInstance(sessionInfo.GridInstance)
    if err != nil || !instance.Healthy {
        return false
    }
    
    return r.sessionExistsOnInstance(sessionInfo.SessionID, instance.URL)
}

func (r *Registry) sessionExistsOnInstance(sessionID, gridURL string) bool {
    client := &http.Client{Timeout: 10 * time.Second}
    
    // Try to get session info from the Grid instance
    resp, err := client.Get(fmt.Sprintf("%s/session/%s", gridURL, sessionID))
    if err != nil {
        return false
    }
    defer resp.Body.Close()
    
    // Session exists if we get a 200 response
    return resp.StatusCode == http.StatusOK
}
```

### Step 3: Add Configuration for Automatic Tracking

```yaml
# Add to config.yaml
loadbalancer:
  # ... existing config ...
  session_monitoring_interval: 30s
  session_discovery_interval: 2m
  automatic_failover: true
  session_verification: true
```

### Step 4: Add Metrics for Tracking

```go
// Add to metrics/metrics.go
var (
    SessionsDiscovered = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "loadbalancer_sessions_discovered_total",
            Help: "Total number of sessions automatically discovered",
        },
        []string{"grid_instance"},
    )
    
    SessionsMigrated = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "loadbalancer_sessions_migrated_total",
            Help: "Total number of sessions automatically migrated during failover",
        },
        []string{"from_instance", "to_instance"},
    )
    
    SessionsVerified = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "loadbalancer_sessions_verified_total",
            Help: "Total number of session verifications performed",
        },
        []string{"result"},
    )
)
```

## Benefits of Automatic Tracking

1. **Zero Client Changes**: No modifications required to existing WebDriver clients
2. **Automatic Discovery**: Finds sessions even if load balancer restarts
3. **Failover Handling**: Automatically detects and handles Grid instance failures
4. **Session Cleanup**: Removes stale sessions automatically
5. **Connection Recovery**: Handles network interruptions transparently
6. **Monitoring**: Provides comprehensive metrics and logging

## Usage Example

With automatic tracking, clients can use standard WebDriver code:

```python
from selenium import webdriver
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

# Standard WebDriver usage - no special headers or configuration needed
driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    desired_capabilities=DesiredCapabilities.CHROME
)

# The load balancer automatically:
# 1. Routes session creation to best Grid instance
# 2. Tracks the session -> Grid instance mapping
# 3. Routes all subsequent requests to the correct instance
# 4. Handles connection failures and failover
# 5. Cleans up when session ends

driver.get("https://example.com")
driver.find_element_by_tag_name("body")
driver.quit()  # Automatically removes session from tracking
```

The load balancer handles all the complexity behind the scenes, providing transparent session affinity and connection recovery without any client-side changes.
