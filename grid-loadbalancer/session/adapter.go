package session

import (
	"time"
)

// GridManagerAdapter adapts the grid manager to work with session registry
type GridManagerAdapter struct {
	manager GridManagerInterface
}

// GridManagerInterface defines the interface that grid managers must implement
type GridManagerInterface interface {
	GetHealthyInstancesForSessionRegistry() []InstanceStatus
	GetInstanceForSessionRegistry(id string) (*InstanceStatus, error)
}

// NewGridManagerAdapter creates a new adapter
func NewGridManagerAdapter(manager GridManagerInterface) *GridManagerAdapter {
	return &GridManagerAdapter{
		manager: manager,
	}
}

// GetHealthyInstances implements the GridManager interface for session registry
func (a *GridManagerAdapter) GetHealthyInstances() []InstanceStatus {
	return a.manager.GetHealthyInstancesForSessionRegistry()
}

// GetInstance implements the GridManager interface for session registry
func (a *GridManagerAdapter) GetInstance(id string) (*InstanceStatus, error) {
	return a.manager.GetInstanceForSessionRegistry(id)
}

// AutomaticSessionTracker handles all automatic session tracking functionality
type AutomaticSessionTracker struct {
	registry    *Registry
	adapter     *GridManagerAdapter
	monitoringEnabled bool
	discoveryEnabled  bool
}

// NewAutomaticSessionTracker creates a new automatic session tracker
func NewAutomaticSessionTracker(registry *Registry, gridManager GridManagerInterface) *AutomaticSessionTracker {
	return &AutomaticSessionTracker{
		registry:          registry,
		adapter:           NewGridManagerAdapter(gridManager),
		monitoringEnabled: true,
		discoveryEnabled:  true,
	}
}

// Start begins automatic session tracking
func (t *AutomaticSessionTracker) Start(monitoringInterval, discoveryInterval time.Duration) {
	if t.monitoringEnabled {
		t.startSessionMonitoring(monitoringInterval)
	}
	
	if t.discoveryEnabled {
		t.startSessionDiscovery(discoveryInterval)
	}
}

// startSessionMonitoring starts the session state monitoring routine
func (t *AutomaticSessionTracker) startSessionMonitoring(interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		
		for {
			select {
			case <-ticker.C:
				t.registry.monitorSessionStates(t.adapter)
			}
		}
	}()
}

// startSessionDiscovery starts the session discovery routine
func (t *AutomaticSessionTracker) startSessionDiscovery(interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		
		for {
			select {
			case <-ticker.C:
				t.registry.DiscoverSessionsFromGrids(t.adapter)
			}
		}
	}()
}

// EnableMonitoring enables or disables session monitoring
func (t *AutomaticSessionTracker) EnableMonitoring(enabled bool) {
	t.monitoringEnabled = enabled
}

// EnableDiscovery enables or disables session discovery
func (t *AutomaticSessionTracker) EnableDiscovery(enabled bool) {
	t.discoveryEnabled = enabled
}

// GetStats returns statistics about automatic session tracking
func (t *AutomaticSessionTracker) GetStats() map[string]interface{} {
	return map[string]interface{}{
		"active_sessions":     t.registry.GetSessionCount(),
		"monitoring_enabled":  t.monitoringEnabled,
		"discovery_enabled":   t.discoveryEnabled,
		"healthy_instances":   len(t.adapter.GetHealthyInstances()),
	}
}
