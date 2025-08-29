package grid

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/selenium/go-grid-loadbalancer/config"
	"github.com/selenium/go-grid-loadbalancer/session"
)

// InstanceStatus represents the health status of a grid instance
type InstanceStatus struct {
	ID             string    `json:"id"`
	URL            string    `json:"url"`
	Healthy        bool      `json:"healthy"`
	LastCheck      time.Time `json:"last_check"`
	ResponseTime   int64     `json:"response_time_ms"`
	ErrorCount     int       `json:"error_count"`
	Priority       int       `json:"priority"`
	Weight         int       `json:"weight"`
	Username       string    `json:"username,omitempty"`       // Basic auth username
	Password       string    `json:"password,omitempty"`       // Basic auth password
	MaxSessions    int       `json:"max_sessions,omitempty"`   // Maximum sessions for Greedy strategy
	CurrentSessions int      `json:"current_sessions"`         // Current active sessions
	Region         string    `json:"region,omitempty"`         // Geographic region for HA GEO
	Role           string    `json:"role,omitempty"`           // Role: "active" or "standby" for HA GEO
}

// GridStatus represents the status response from a Grid instance
type GridStatus struct {
	Ready bool `json:"ready"`
	Value struct {
		Ready   bool `json:"ready"`
		Message string `json:"message"`
		Nodes   []struct {
			ID           string `json:"id"`
			URI          string `json:"uri"`
			MaxSessions  int    `json:"maxSessions"`
			Slots        []struct {
				ID      string `json:"id"`
				Session struct {
					SessionID string `json:"sessionId"`
				} `json:"session"`
			} `json:"slots"`
			Stereotypes []interface{} `json:"stereotypes"`
		} `json:"nodes"`
	} `json:"value"`
}

// Manager manages multiple Grid instances with health checking and load balancing
type Manager struct {
	mu                sync.RWMutex
	instances         map[string]*InstanceStatus
	client            *http.Client
	config            *config.Config
	roundRobinCounter int // Counter for weighted round robin
}

// NewManager creates a new Grid instance manager
func NewManager(cfg *config.Config) *Manager {
	manager := &Manager{
		instances: make(map[string]*InstanceStatus),
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		config: cfg,
	}

	// Initialize instances from config
	for _, instance := range cfg.GridInstances {
		if instance.Enabled {
			manager.instances[instance.ID] = &InstanceStatus{
				ID:              instance.ID,
				URL:             instance.URL,
				Healthy:         false,
				Priority:        instance.Priority,
				Weight:          instance.Weight,
				Username:        instance.Username, // Include basic auth credentials
				Password:        instance.Password,
				MaxSessions:     instance.MaxSessions, // For Greedy strategy
				CurrentSessions: 0,                    // Initialize session count
				Region:          instance.Region,      // For HA GEO strategy
				Role:            instance.Role,        // For HA GEO strategy
			}
		}
	}

	return manager
}

// GetBestInstanceForNewSession selects the best instance for a new session based on the configured strategy
func (m *Manager) GetBestInstanceForNewSession() (*InstanceStatus, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	strategy := m.config.LoadBalancer.Strategy
	healthyInstances := m.getHealthyInstancesInternal()
	
	if len(healthyInstances) == 0 {
		return nil, fmt.Errorf("no healthy grid instances available")
	}

	switch strings.ToLower(strategy) {
	case "weighted_round_robin":
		return m.selectWeightedRoundRobin(healthyInstances), nil
	case "ha_geo":
		return m.selectHAGeo(healthyInstances), nil
	case "greedy":
		return m.selectGreedy(healthyInstances), nil
	default:
		log.Printf("Unknown load balancing strategy: %s, falling back to weighted_round_robin", strategy)
		return m.selectWeightedRoundRobin(healthyInstances), nil
	}
}

// selectWeightedRoundRobin implements weighted round robin load balancing
func (m *Manager) selectWeightedRoundRobin(instances []*InstanceStatus) *InstanceStatus {
	if len(instances) == 0 {
		return nil
	}

	// Sort instances by priority first, then by ID for consistent ordering
	sort.Slice(instances, func(i, j int) bool {
		if instances[i].Priority != instances[j].Priority {
			return instances[i].Priority < instances[j].Priority // Lower priority number = higher priority
		}
		return instances[i].ID < instances[j].ID
	})

	// Calculate total weight for instances with the same priority as the first instance
	highestPriority := instances[0].Priority
	var eligibleInstances []*InstanceStatus
	totalWeight := 0

	for _, instance := range instances {
		if instance.Priority == highestPriority {
			eligibleInstances = append(eligibleInstances, instance)
			weight := instance.Weight
			if weight <= 0 {
				weight = 1 // Default weight
			}
			totalWeight += weight
		} else {
			break // Stop when we reach lower priority instances
		}
	}

	if totalWeight == 0 {
		return eligibleInstances[0] // Fallback to first instance
	}

	// Weighted round robin selection
	m.roundRobinCounter++
	targetWeight := m.roundRobinCounter % totalWeight
	currentWeight := 0

	for _, instance := range eligibleInstances {
		weight := instance.Weight
		if weight <= 0 {
			weight = 1
		}
		currentWeight += weight
		if currentWeight > targetWeight {
			log.Printf("Weighted Round Robin selected instance %s (weight: %d, counter: %d)", 
				instance.ID, weight, m.roundRobinCounter)
			return instance
		}
	}

	return eligibleInstances[0] // Fallback
}

// selectHAGeo implements High Availability Geographic load balancing (Active/Standby)
func (m *Manager) selectHAGeo(instances []*InstanceStatus) *InstanceStatus {
	if len(instances) == 0 {
		return nil
	}

	// Group instances by region and role
	activeInstances := make(map[string][]*InstanceStatus)
	standbyInstances := make(map[string][]*InstanceStatus)

	for _, instance := range instances {
		region := instance.Region
		if region == "" {
			region = "default"
		}

		role := strings.ToLower(instance.Role)
		switch role {
		case "active":
			activeInstances[region] = append(activeInstances[region], instance)
		case "standby":
			standbyInstances[region] = append(standbyInstances[region], instance)
		default:
			// If no role specified, treat as active
			activeInstances[region] = append(activeInstances[region], instance)
		}
	}

	// Try to find an active instance first
	for region, actives := range activeInstances {
		if len(actives) > 0 {
			// Sort by priority within the region
			sort.Slice(actives, func(i, j int) bool {
				if actives[i].Priority != actives[j].Priority {
					return actives[i].Priority < actives[j].Priority
				}
				return actives[i].ID < actives[j].ID
			})
			
			selected := actives[0]
			log.Printf("HA GEO selected active instance %s in region %s", selected.ID, region)
			return selected
		}
	}

	// If no active instances available, fall back to standby instances
	for region, standbys := range standbyInstances {
		if len(standbys) > 0 {
			sort.Slice(standbys, func(i, j int) bool {
				if standbys[i].Priority != standbys[j].Priority {
					return standbys[i].Priority < standbys[j].Priority
				}
				return standbys[i].ID < standbys[j].ID
			})
			
			selected := standbys[0]
			log.Printf("HA GEO selected standby instance %s in region %s (no active available)", selected.ID, region)
			return selected
		}
	}

	// Final fallback - return first available instance
	return instances[0]
}

// selectGreedy implements greedy load balancing based on maximum session limits
func (m *Manager) selectGreedy(instances []*InstanceStatus) *InstanceStatus {
	if len(instances) == 0 {
		return nil
	}

	// Sort instances by priority first
	sort.Slice(instances, func(i, j int) bool {
		if instances[i].Priority != instances[j].Priority {
			return instances[i].Priority < instances[j].Priority
		}
		return instances[i].ID < instances[j].ID
	})

	// Find the first instance that hasn't reached its session limit
	for _, instance := range instances {
		maxSessions := instance.MaxSessions
		if maxSessions <= 0 {
			maxSessions = math.MaxInt32 // No limit if not specified
		}

		if instance.CurrentSessions < maxSessions {
			log.Printf("Greedy selected instance %s (sessions: %d/%d, priority: %d)", 
				instance.ID, instance.CurrentSessions, maxSessions, instance.Priority)
			return instance
		}
	}

	// If all instances are at capacity, return the one with the lowest session count
	sort.Slice(instances, func(i, j int) bool {
		if instances[i].CurrentSessions != instances[j].CurrentSessions {
			return instances[i].CurrentSessions < instances[j].CurrentSessions
		}
		if instances[i].Priority != instances[j].Priority {
			return instances[i].Priority < instances[j].Priority
		}
		return instances[i].ID < instances[j].ID
	})

	selected := instances[0]
	log.Printf("Greedy selected instance %s (all at capacity, lowest sessions: %d)", 
		selected.ID, selected.CurrentSessions)
	return selected
}

// IncrementSessionCount increments the session count for an instance
func (m *Manager) IncrementSessionCount(instanceID string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	if instance, exists := m.instances[instanceID]; exists {
		instance.CurrentSessions++
		log.Printf("Incremented session count for instance %s: %d", instanceID, instance.CurrentSessions)
	}
}

// DecrementSessionCount decrements the session count for an instance
func (m *Manager) DecrementSessionCount(instanceID string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	if instance, exists := m.instances[instanceID]; exists {
		if instance.CurrentSessions > 0 {
			instance.CurrentSessions--
		}
		log.Printf("Decremented session count for instance %s: %d", instanceID, instance.CurrentSessions)
	}
}

// getHealthyInstancesInternal returns healthy instances (internal method, assumes lock is held)
func (m *Manager) getHealthyInstancesInternal() []*InstanceStatus {
	var healthy []*InstanceStatus
	for _, instance := range m.instances {
		if instance.Healthy {
			healthy = append(healthy, instance)
		}
	}
	return healthy
}

// StartHealthChecking starts the health checking routine
func (m *Manager) StartHealthChecking() {
	ticker := time.NewTicker(m.config.LoadBalancer.HealthCheckInterval)
	go func() {
		for {
			select {
			case <-ticker.C:
				m.checkAllInstances()
			}
		}
	}()

	// Initial health check
	m.checkAllInstances()
}

// checkAllInstances performs health checks on all grid instances
func (m *Manager) checkAllInstances() {
	var wg sync.WaitGroup
	
	m.mu.RLock()
	instances := make([]*InstanceStatus, 0, len(m.instances))
	for _, instance := range m.instances {
		instances = append(instances, instance)
	}
	m.mu.RUnlock()

	for _, instance := range instances {
		wg.Add(1)
		go func(inst *InstanceStatus) {
			defer wg.Done()
			m.checkInstance(inst)
		}(instance)
	}

	wg.Wait()
}

// checkInstance performs a health check on a single grid instance
func (m *Manager) checkInstance(instance *InstanceStatus) {
	start := time.Now()
	
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, "GET", instance.URL+"/status", nil)
	if err != nil {
		m.markUnhealthy(instance, fmt.Errorf("failed to create request: %w", err))
		return
	}

	// Add basic authentication if credentials are provided
	if instance.Username != "" && instance.Password != "" {
		req.SetBasicAuth(instance.Username, instance.Password)
	}

	resp, err := m.client.Do(req)
	if err != nil {
		m.markUnhealthy(instance, fmt.Errorf("request failed: %w", err))
		return
	}
	defer resp.Body.Close()

	responseTime := time.Since(start).Milliseconds()

	if resp.StatusCode != http.StatusOK {
		m.markUnhealthy(instance, fmt.Errorf("unexpected status code: %d", resp.StatusCode))
		return
	}

	var status GridStatus
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		m.markUnhealthy(instance, fmt.Errorf("failed to decode response: %w", err))
		return
	}

	if !status.Ready {
		m.markUnhealthy(instance, fmt.Errorf("grid instance not ready"))
		return
	}

	m.markHealthy(instance, responseTime)
}

// markHealthy marks an instance as healthy
func (m *Manager) markHealthy(instance *InstanceStatus, responseTime int64) {
	m.mu.Lock()
	defer m.mu.Unlock()

	wasUnhealthy := !instance.Healthy
	instance.Healthy = true
	instance.LastCheck = time.Now()
	instance.ResponseTime = responseTime
	instance.ErrorCount = 0

	if wasUnhealthy {
		log.Printf("Grid instance %s (%s) is now healthy (response time: %dms)", 
			instance.ID, instance.URL, responseTime)
	}
}

// markUnhealthy marks an instance as unhealthy
func (m *Manager) markUnhealthy(instance *InstanceStatus, err error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	wasHealthy := instance.Healthy
	instance.Healthy = false
	instance.LastCheck = time.Now()
	instance.ErrorCount++

	if wasHealthy {
		log.Printf("Grid instance %s (%s) is now unhealthy: %v", 
			instance.ID, instance.URL, err)
	}
}

// GetHealthyInstances returns all healthy grid instances
func (m *Manager) GetHealthyInstances() []*InstanceStatus {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var healthy []*InstanceStatus
	for _, instance := range m.instances {
		if instance.Healthy {
			healthy = append(healthy, &InstanceStatus{
				ID:           instance.ID,
				URL:          instance.URL,
				Healthy:      instance.Healthy,
				LastCheck:    instance.LastCheck,
				ResponseTime: instance.ResponseTime,
				ErrorCount:   instance.ErrorCount,
				Priority:     instance.Priority,
				Weight:       instance.Weight,
			})
		}
	}

	return healthy
}

// GetHealthyInstancesForSessionRegistry returns instances in format expected by session registry
func (m *Manager) GetHealthyInstancesForSessionRegistry() []session.InstanceStatus {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var healthy []session.InstanceStatus
	for _, instance := range m.instances {
		if instance.Healthy {
			healthy = append(healthy, session.InstanceStatus{
				ID:  instance.ID,
				URL: instance.URL,
			})
		}
	}

	return healthy
}

// GetInstanceForSessionRegistry returns instance in format expected by session registry
func (m *Manager) GetInstanceForSessionRegistry(id string) (*session.InstanceStatus, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	instance, exists := m.instances[id]
	if !exists {
		return nil, fmt.Errorf("grid instance %s not found", id)
	}

	return &session.InstanceStatus{
		ID:  instance.ID,
		URL: instance.URL,
	}, nil
}

// GetBestInstance returns the best available grid instance for new sessions
func (m *Manager) GetBestInstance() (*InstanceStatus, error) {
	healthy := m.GetHealthyInstances()
	if len(healthy) == 0 {
		return nil, fmt.Errorf("no healthy grid instances available")
	}

	// Sort by priority (lower number = higher priority), then by response time
	best := healthy[0]
	for _, instance := range healthy[1:] {
		if instance.Priority < best.Priority || 
		   (instance.Priority == best.Priority && instance.ResponseTime < best.ResponseTime) {
			best = instance
		}
	}

	return best, nil
}

// GetInstance returns a specific grid instance by ID
func (m *Manager) GetInstance(id string) (*InstanceStatus, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	instance, exists := m.instances[id]
	if !exists {
		return nil, fmt.Errorf("grid instance %s not found", id)
	}

	return &InstanceStatus{
		ID:           instance.ID,
		URL:          instance.URL,
		Healthy:      instance.Healthy,
		LastCheck:    instance.LastCheck,
		ResponseTime: instance.ResponseTime,
		ErrorCount:   instance.ErrorCount,
		Priority:     instance.Priority,
		Weight:       instance.Weight,
	}, nil
}

// GetAllInstances returns all grid instances with their status
func (m *Manager) GetAllInstances() []*InstanceStatus {
	m.mu.RLock()
	defer m.mu.RUnlock()

	var all []*InstanceStatus
	for _, instance := range m.instances {
		all = append(all, &InstanceStatus{
			ID:           instance.ID,
			URL:          instance.URL,
			Healthy:      instance.Healthy,
			LastCheck:    instance.LastCheck,
			ResponseTime: instance.ResponseTime,
			ErrorCount:   instance.ErrorCount,
			Priority:     instance.Priority,
			Weight:       instance.Weight,
		})
	}

	return all
}

// IsInstanceHealthy checks if a specific instance is healthy
func (m *Manager) IsInstanceHealthy(id string) bool {
	m.mu.RLock()
	defer m.mu.RUnlock()

	instance, exists := m.instances[id]
	return exists && instance.Healthy
}

// GetHealthyInstanceCount returns the number of healthy instances
func (m *Manager) GetHealthyInstanceCount() int {
	m.mu.RLock()
	defer m.mu.RUnlock()

	count := 0
	for _, instance := range m.instances {
		if instance.Healthy {
			count++
		}
	}
	return count
}
