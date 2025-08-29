package proxy

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strings"
	"time"

	"github.com/selenium/go-grid-loadbalancer/config"
	"github.com/selenium/go-grid-loadbalancer/grid"
	"github.com/selenium/go-grid-loadbalancer/session"
)

// Router handles HTTP requests and routes them to appropriate Grid instances
type Router struct {
	sessionRegistry *session.Registry
	gridManager     *grid.Manager
	config          *config.Config
	sessionIDRegex  *regexp.Regexp
	client          *http.Client
}

// SessionCreationResponse represents the response from session creation
type SessionCreationResponse struct {
	Value struct {
		SessionID    string                 `json:"sessionId"`
		Capabilities map[string]interface{} `json:"capabilities"`
	} `json:"value"`
}

// NewRouter creates a new HTTP router
func NewRouter(sessionRegistry *session.Registry, gridManager *grid.Manager, cfg *config.Config) *Router {
	return &Router{
		sessionRegistry: sessionRegistry,
		gridManager:     gridManager,
		config:          cfg,
		sessionIDRegex:  regexp.MustCompile(`/session/([^/]+)`),
		client: &http.Client{
			Timeout: 300 * time.Second, // Long timeout for WebDriver operations
		},
	}
}

// ServeHTTP implements the http.Handler interface
func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	start := time.Now()
	
	// Add CORS headers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Client-UUID")
	
	if req.Method == "OPTIONS" {
		w.WriteHeader(http.StatusOK)
		return
	}

	// Handle status endpoint
	if req.URL.Path == "/status" {
		r.handleStatus(w, req)
		return
	}

	// Handle load balancer specific endpoints
	if strings.HasPrefix(req.URL.Path, "/lb/") {
		r.handleLoadBalancerEndpoints(w, req)
		return
	}

	// Extract client UUID from headers
	clientUUID := req.Header.Get("X-Client-UUID")
	clientIP := getClientIP(req)
	userAgent := req.Header.Get("User-Agent")

	// Check if this is a session creation request
	if req.Method == "POST" && req.URL.Path == "/session" {
		r.handleSessionCreation(w, req, clientUUID, clientIP, userAgent)
		return
	}

	// Extract session ID from URL
	sessionID := r.extractSessionID(req.URL.Path)
	if sessionID == "" {
		// No session ID in URL, route to best available instance
		r.routeToInstance(w, req, "", start)
		return
	}

	// Try to find the grid instance for this session
	gridInstanceID, err := r.sessionRegistry.GetGridInstance(sessionID)
	if err != nil {
		// Session not found, try to recover using client UUID
		if clientUUID != "" {
			recoveredSessionID, err := r.sessionRegistry.GetSessionByClientUUID(clientUUID)
			if err == nil && recoveredSessionID == sessionID {
				log.Printf("Session %s recovered using client UUID %s", sessionID, clientUUID)
				// Try to find grid instance again
				gridInstanceID, err = r.sessionRegistry.GetGridInstance(sessionID)
			}
		}
		
		if err != nil {
			log.Printf("Session %s not found in registry, attempting to route to any healthy instance", sessionID)
			r.routeToInstance(w, req, "", start)
			return
		}
	}

	// Check if the target grid instance is healthy
	if !r.gridManager.IsInstanceHealthy(gridInstanceID) {
		log.Printf("Grid instance %s for session %s is unhealthy, attempting failover", gridInstanceID, sessionID)
		r.handleFailover(w, req, sessionID, gridInstanceID, start)
		return
	}

	// Route to the specific grid instance
	r.routeToInstance(w, req, gridInstanceID, start)
}

// handleSessionCreation handles new session creation requests
func (r *Router) handleSessionCreation(w http.ResponseWriter, req *http.Request, clientUUID, clientIP, userAgent string) {
	// Get the best available grid instance using the configured load balancing strategy
	instance, err := r.gridManager.GetBestInstanceForNewSession()
	if err != nil {
		http.Error(w, fmt.Sprintf("No healthy grid instances available: %v", err), http.StatusServiceUnavailable)
		return
	}

	// Generate client UUID if not provided
	if clientUUID == "" {
		clientUUID = session.GenerateClientUUID()
	}

	// Read the request body
	body, err := io.ReadAll(req.Body)
	if err != nil {
		http.Error(w, "Failed to read request body", http.StatusBadRequest)
		return
	}
	req.Body.Close()

	// Create a new request to the selected grid instance
	targetURL := instance.URL + req.URL.Path
	proxyReq, err := http.NewRequest(req.Method, targetURL, bytes.NewReader(body))
	if err != nil {
		http.Error(w, "Failed to create proxy request", http.StatusInternalServerError)
		return
	}

	// Copy headers
	for name, values := range req.Header {
		for _, value := range values {
			proxyReq.Header.Add(name, value)
		}
	}

	// Add client UUID header
	proxyReq.Header.Set("X-Client-UUID", clientUUID)

	// Execute the request
	resp, err := r.client.Do(proxyReq)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to execute request: %v", err), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Failed to read response body", http.StatusInternalServerError)
		return
	}

	// Copy response headers
	for name, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(name, value)
		}
	}

	// Add client UUID to response headers
	w.Header().Set("X-Client-UUID", clientUUID)
	w.WriteHeader(resp.StatusCode)
	w.Write(respBody)

	// If session creation was successful, register the session and increment session count
	if resp.StatusCode == http.StatusOK {
		var sessionResp SessionCreationResponse
		if err := json.Unmarshal(respBody, &sessionResp); err == nil && sessionResp.Value.SessionID != "" {
			sessionID := sessionResp.Value.SessionID
			err := r.sessionRegistry.RegisterSession(sessionID, instance.ID, clientUUID, userAgent, clientIP)
			if err != nil {
				log.Printf("Failed to register session %s: %v", sessionID, err)
			} else {
				// Increment session count for load balancing strategies
				r.gridManager.IncrementSessionCount(instance.ID)
				log.Printf("Session %s created on grid instance %s (client UUID: %s)", sessionID, instance.ID, clientUUID)
			}
		}
	}
}

// routeToInstance routes a request to a specific grid instance with intelligent retry strategy
func (r *Router) routeToInstance(w http.ResponseWriter, req *http.Request, gridInstanceID string, start time.Time) {
	// Use intelligent retry strategy
	success := r.executeWithIntelligentRetry(w, req, gridInstanceID, start)
	if !success {
		http.Error(w, "All grid instances failed after retries", http.StatusServiceUnavailable)
	}
}

// executeWithIntelligentRetry implements smart retry strategy based on available Grid instances
func (r *Router) executeWithIntelligentRetry(w http.ResponseWriter, req *http.Request, preferredInstanceID string, start time.Time) bool {
	healthyInstances := r.gridManager.GetHealthyInstances()
	if len(healthyInstances) == 0 {
		log.Printf("No healthy grid instances available")
		return false
	}

	maxRetries := r.config.LoadBalancer.MaxRetries
	retryInterval := r.config.LoadBalancer.RetryInterval
	numInstances := len(healthyInstances)

	// Calculate retry strategy based on MaxRetries vs GridInstance count
	var retryPlan []string
	
	if maxRetries <= numInstances {
		// Strategy 1: MaxRetries <= GridInstance count
		// Try one-by-one on different instances until success or maxRetries reached
		retryPlan = r.buildRetryPlanOneByOne(healthyInstances, preferredInstanceID, maxRetries)
	} else {
		// Strategy 2: MaxRetries > GridInstance count  
		// Try one-by-one until reach max GridInstance then repeat cycles
		retryPlan = r.buildRetryPlanWithCycles(healthyInstances, preferredInstanceID, maxRetries)
	}

	log.Printf("Executing retry strategy: %d retries across %d instances (plan: %v)", 
		len(retryPlan), numInstances, retryPlan)

	// Execute retry plan
	for attempt, instanceID := range retryPlan {
		instance, err := r.gridManager.GetInstance(instanceID)
		if err != nil || !instance.Healthy {
			log.Printf("Attempt %d: Instance %s not available, skipping", attempt+1, instanceID)
			continue
		}

		log.Printf("Attempt %d: Trying instance %s", attempt+1, instanceID)
		
		if r.executeRequestOnInstance(w, req, instance, start, attempt == 0) {
			log.Printf("Request succeeded on instance %s after %d attempts", instanceID, attempt+1)
			return true
		}

		// Wait before next retry (except for last attempt)
		if attempt < len(retryPlan)-1 {
			time.Sleep(retryInterval)
		}
	}

	log.Printf("All retry attempts failed after %d tries", len(retryPlan))
	return false
}

// buildRetryPlanOneByOne creates retry plan for MaxRetries <= GridInstance scenario
func (r *Router) buildRetryPlanOneByOne(instances []*grid.InstanceStatus, preferredInstanceID string, maxRetries int) []string {
	var plan []string
	usedInstances := make(map[string]bool)

	// Try preferred instance first if specified and available
	if preferredInstanceID != "" {
		for _, instance := range instances {
			if instance.ID == preferredInstanceID && instance.Healthy {
				plan = append(plan, preferredInstanceID)
				usedInstances[preferredInstanceID] = true
				break
			}
		}
	}

	// Add other instances until maxRetries reached
	for _, instance := range instances {
		if len(plan) >= maxRetries {
			break
		}
		if !usedInstances[instance.ID] && instance.Healthy {
			plan = append(plan, instance.ID)
			usedInstances[instance.ID] = true
		}
	}

	return plan
}

// buildRetryPlanWithCycles creates retry plan for MaxRetries > GridInstance scenario
func (r *Router) buildRetryPlanWithCycles(instances []*grid.InstanceStatus, preferredInstanceID string, maxRetries int) []string {
	var plan []string
	numInstances := len(instances)

	// Create ordered list starting with preferred instance
	var orderedInstances []string
	usedInstances := make(map[string]bool)

	// Add preferred instance first if available
	if preferredInstanceID != "" {
		for _, instance := range instances {
			if instance.ID == preferredInstanceID && instance.Healthy {
				orderedInstances = append(orderedInstances, preferredInstanceID)
				usedInstances[preferredInstanceID] = true
				break
			}
		}
	}

	// Add remaining instances
	for _, instance := range instances {
		if !usedInstances[instance.ID] && instance.Healthy {
			orderedInstances = append(orderedInstances, instance.ID)
		}
	}

	// Build retry plan with cycles
	for i := 0; i < maxRetries; i++ {
		instanceIndex := i % numInstances
		plan = append(plan, orderedInstances[instanceIndex])
	}

	return plan
}

// executeRequestOnInstance executes the request on a specific instance
func (r *Router) executeRequestOnInstance(w http.ResponseWriter, req *http.Request, instance *grid.InstanceStatus, start time.Time, isFirstAttempt bool) bool {
	// Parse target URL
	targetURL, err := url.Parse(instance.URL)
	if err != nil {
		log.Printf("Invalid grid instance URL for %s: %v", instance.ID, err)
		return false
	}

	// Create reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(targetURL)
	
	// Customize the proxy to handle errors and add logging
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Header.Set("X-Forwarded-Host", req.Header.Get("Host"))
		req.Header.Set("X-Load-Balancer", "selenium-grid-lb")
		req.Header.Set("X-Grid-Instance", instance.ID)
		
		// Add basic authentication if credentials are provided
		if instance.Username != "" && instance.Password != "" {
			req.SetBasicAuth(instance.Username, instance.Password)
		}
	}

	// Track success/failure for this attempt
	requestSucceeded := true
	
	proxy.ErrorHandler = func(w http.ResponseWriter, req *http.Request, err error) {
		log.Printf("Proxy error for %s on instance %s: %v", req.URL.Path, instance.ID, err)
		requestSucceeded = false
		
		// Only write error response if this is not a retry attempt
		if isFirstAttempt {
			http.Error(w, "Bad Gateway", http.StatusBadGateway)
		}
	}

	// Execute the proxy request
	proxy.ServeHTTP(w, req)

	// Handle session termination to decrement session count
	sessionID := r.extractSessionID(req.URL.Path)
	if sessionID != "" && req.Method == "DELETE" {
		// Session is being terminated, decrement session count
		r.gridManager.DecrementSessionCount(instance.ID)
		log.Printf("Session %s terminated on instance %s", sessionID, instance.ID)
	}

	// Log the request
	duration := time.Since(start)
	log.Printf("Routed %s %s (session: %s) to %s in %v", 
		req.Method, req.URL.Path, sessionID, instance.ID, duration)

	return requestSucceeded
}

// handleFailover attempts to handle failover for a session with automatic session migration
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
				log.Printf("Automatically migrated session %s from %s to instance %s", sessionID, failedInstanceID, instance.ID)
				
				// Route the request to the new instance
				r.routeToInstance(w, req, instance.ID, start)
				return
			}
		}
	}
	
	// If session not found on any instance, try routing to best available instance
	// This handles cases where the session might still be accessible
	log.Printf("Session %s not found on any healthy instance, routing to best available", sessionID)
	r.routeToInstance(w, req, "", start)
	
	// If this is a session termination request, clean up the registry
	if req.Method == "DELETE" || strings.Contains(req.URL.Path, "/window") {
		r.sessionRegistry.RemoveSession(sessionID)
		log.Printf("Cleaned up session %s from registry after failover", sessionID)
	}
}

// sessionExistsOnInstance checks if a session exists on a specific Grid instance
func (r *Router) sessionExistsOnInstance(sessionID, gridURL string) bool {
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

// extractSessionID extracts the session ID from a URL path
func (r *Router) extractSessionID(path string) string {
	matches := r.sessionIDRegex.FindStringSubmatch(path)
	if len(matches) > 1 {
		return matches[1]
	}
	return ""
}

// handleStatus handles the load balancer status endpoint
func (r *Router) handleStatus(w http.ResponseWriter, req *http.Request) {
	status := map[string]interface{}{
		"ready": true,
		"value": map[string]interface{}{
			"ready":   true,
			"message": "Load balancer is ready",
			"grid_instances": r.gridManager.GetAllInstances(),
			"active_sessions": r.sessionRegistry.GetSessionCount(),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

// handleLoadBalancerEndpoints handles load balancer specific endpoints
func (r *Router) handleLoadBalancerEndpoints(w http.ResponseWriter, req *http.Request) {
	switch req.URL.Path {
	case "/lb/health":
		r.handleHealthEndpoint(w, req)
	case "/lb/sessions":
		r.handleSessionsEndpoint(w, req)
	case "/lb/instances":
		r.handleInstancesEndpoint(w, req)
	default:
		http.NotFound(w, req)
	}
}

// handleHealthEndpoint provides health information
func (r *Router) handleHealthEndpoint(w http.ResponseWriter, req *http.Request) {
	healthyCount := r.gridManager.GetHealthyInstanceCount()
	totalCount := len(r.gridManager.GetAllInstances())
	
	health := map[string]interface{}{
		"healthy": healthyCount > 0,
		"healthy_instances": healthyCount,
		"total_instances": totalCount,
		"active_sessions": r.sessionRegistry.GetSessionCount(),
	}

	w.Header().Set("Content-Type", "application/json")
	if healthyCount == 0 {
		w.WriteHeader(http.StatusServiceUnavailable)
	}
	json.NewEncoder(w).Encode(health)
}

// handleSessionsEndpoint provides session information
func (r *Router) handleSessionsEndpoint(w http.ResponseWriter, req *http.Request) {
	sessions := map[string]interface{}{
		"active_sessions": r.sessionRegistry.GetSessionCount(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(sessions)
}

// handleInstancesEndpoint provides grid instance information
func (r *Router) handleInstancesEndpoint(w http.ResponseWriter, req *http.Request) {
	instances := map[string]interface{}{
		"instances": r.gridManager.GetAllInstances(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(instances)
}

// getClientIP extracts the client IP address from the request
func getClientIP(req *http.Request) string {
	// Check X-Forwarded-For header first
	if xff := req.Header.Get("X-Forwarded-For"); xff != "" {
		ips := strings.Split(xff, ",")
		return strings.TrimSpace(ips[0])
	}
	
	// Check X-Real-IP header
	if xri := req.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	
	// Fall back to RemoteAddr
	ip := req.RemoteAddr
	if colon := strings.LastIndex(ip, ":"); colon != -1 {
		ip = ip[:colon]
	}
	return ip
}
