package session

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/google/uuid"
)

// SessionInfo represents session information stored in the registry
type SessionInfo struct {
	SessionID    string    `json:"session_id"`
	GridInstance string    `json:"grid_instance"`
	ClientUUID   string    `json:"client_uuid"`
	CreatedAt    time.Time `json:"created_at"`
	LastAccessed time.Time `json:"last_accessed"`
	UserAgent    string    `json:"user_agent,omitempty"`
	ClientIP     string    `json:"client_ip,omitempty"`
}

// Registry manages session to grid instance mappings
type Registry struct {
	mu          sync.RWMutex
	sessions    map[string]*SessionInfo // sessionID -> SessionInfo
	clientUUIDs map[string]string       // clientUUID -> sessionID
	redisClient *redis.Client
	keyTTL      time.Duration
	enabled     bool
}

// NewRegistry creates a new session registry
func NewRegistry(redisEnabled bool, redisHost string, redisPort int, redisPassword string, redisDB int, keyTTL time.Duration) *Registry {
	registry := &Registry{
		sessions:    make(map[string]*SessionInfo),
		clientUUIDs: make(map[string]string),
		keyTTL:      keyTTL,
		enabled:     redisEnabled,
	}

	if redisEnabled {
		registry.redisClient = redis.NewClient(&redis.Options{
			Addr:     fmt.Sprintf("%s:%d", redisHost, redisPort),
			Password: redisPassword,
			DB:       redisDB,
		})

		// Test Redis connection
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		
		if err := registry.redisClient.Ping(ctx).Err(); err != nil {
			log.Printf("Warning: Redis connection failed, falling back to in-memory storage: %v", err)
			registry.enabled = false
		} else {
			log.Println("Redis connection established for session registry")
		}
	}

	return registry
}

// RegisterSession registers a new session with the specified grid instance
func (r *Registry) RegisterSession(sessionID, gridInstance, clientUUID, userAgent, clientIP string) error {
	sessionInfo := &SessionInfo{
		SessionID:    sessionID,
		GridInstance: gridInstance,
		ClientUUID:   clientUUID,
		CreatedAt:    time.Now(),
		LastAccessed: time.Now(),
		UserAgent:    userAgent,
		ClientIP:     clientIP,
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	// Store in memory
	r.sessions[sessionID] = sessionInfo
	if clientUUID != "" {
		r.clientUUIDs[clientUUID] = sessionID
	}

	// Store in Redis if enabled
	if r.enabled {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		data, err := json.Marshal(sessionInfo)
		if err != nil {
			return fmt.Errorf("failed to marshal session info: %w", err)
		}

		key := fmt.Sprintf("session:%s", sessionID)
		if err := r.redisClient.Set(ctx, key, data, r.keyTTL).Err(); err != nil {
			log.Printf("Warning: Failed to store session in Redis: %v", err)
		}

		if clientUUID != "" {
			uuidKey := fmt.Sprintf("client_uuid:%s", clientUUID)
			if err := r.redisClient.Set(ctx, uuidKey, sessionID, r.keyTTL).Err(); err != nil {
				log.Printf("Warning: Failed to store client UUID mapping in Redis: %v", err)
			}
		}
	}

	log.Printf("Registered session %s with grid instance %s (client UUID: %s)", sessionID, gridInstance, clientUUID)
	return nil
}

// GetGridInstance returns the grid instance for a given session ID
func (r *Registry) GetGridInstance(sessionID string) (string, error) {
	r.mu.RLock()
	sessionInfo, exists := r.sessions[sessionID]
	r.mu.RUnlock()

	if exists {
		// Update last accessed time
		r.updateLastAccessed(sessionID)
		return sessionInfo.GridInstance, nil
	}

	// Try Redis if enabled
	if r.enabled {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		key := fmt.Sprintf("session:%s", sessionID)
		data, err := r.redisClient.Get(ctx, key).Result()
		if err == nil {
			var sessionInfo SessionInfo
			if err := json.Unmarshal([]byte(data), &sessionInfo); err == nil {
				// Cache in memory
				r.mu.Lock()
				r.sessions[sessionID] = &sessionInfo
				if sessionInfo.ClientUUID != "" {
					r.clientUUIDs[sessionInfo.ClientUUID] = sessionID
				}
				r.mu.Unlock()

				r.updateLastAccessed(sessionID)
				return sessionInfo.GridInstance, nil
			}
		}
	}

	return "", fmt.Errorf("session %s not found", sessionID)
}

// GetSessionByClientUUID returns the session ID for a given client UUID
func (r *Registry) GetSessionByClientUUID(clientUUID string) (string, error) {
	r.mu.RLock()
	sessionID, exists := r.clientUUIDs[clientUUID]
	r.mu.RUnlock()

	if exists {
		return sessionID, nil
	}

	// Try Redis if enabled
	if r.enabled {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		uuidKey := fmt.Sprintf("client_uuid:%s", clientUUID)
		sessionID, err := r.redisClient.Get(ctx, uuidKey).Result()
		if err == nil {
			// Cache in memory
			r.mu.Lock()
			r.clientUUIDs[clientUUID] = sessionID
			r.mu.Unlock()
			return sessionID, nil
		}
	}

	return "", fmt.Errorf("client UUID %s not found", clientUUID)
}

// RemoveSession removes a session from the registry
func (r *Registry) RemoveSession(sessionID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	sessionInfo, exists := r.sessions[sessionID]
	if exists {
		delete(r.sessions, sessionID)
		if sessionInfo.ClientUUID != "" {
			delete(r.clientUUIDs, sessionInfo.ClientUUID)
		}
	}

	// Remove from Redis if enabled
	if r.enabled {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		key := fmt.Sprintf("session:%s", sessionID)
		if err := r.redisClient.Del(ctx, key).Err(); err != nil {
			log.Printf("Warning: Failed to remove session from Redis: %v", err)
		}

		if sessionInfo != nil && sessionInfo.ClientUUID != "" {
			uuidKey := fmt.Sprintf("client_uuid:%s", sessionInfo.ClientUUID)
			if err := r.redisClient.Del(ctx, uuidKey).Err(); err != nil {
				log.Printf("Warning: Failed to remove client UUID mapping from Redis: %v", err)
			}
		}
	}

	log.Printf("Removed session %s from registry", sessionID)
	return nil
}

// updateLastAccessed updates the last accessed time for a session
func (r *Registry) updateLastAccessed(sessionID string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if sessionInfo, exists := r.sessions[sessionID]; exists {
		sessionInfo.LastAccessed = time.Now()

		// Update in Redis if enabled
		if r.enabled {
			go func() {
				ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
				defer cancel()

				data, err := json.Marshal(sessionInfo)
				if err != nil {
					return
				}

				key := fmt.Sprintf("session:%s", sessionID)
				r.redisClient.Set(ctx, key, data, r.keyTTL)
			}()
		}
	}
}

// CleanupExpiredSessions removes expired sessions from the registry
func (r *Registry) CleanupExpiredSessions(maxAge time.Duration) {
	r.mu.Lock()
	defer r.mu.Unlock()

	now := time.Now()
	var expiredSessions []string

	for sessionID, sessionInfo := range r.sessions {
		if now.Sub(sessionInfo.LastAccessed) > maxAge {
			expiredSessions = append(expiredSessions, sessionID)
		}
	}

	for _, sessionID := range expiredSessions {
		sessionInfo := r.sessions[sessionID]
		delete(r.sessions, sessionID)
		if sessionInfo.ClientUUID != "" {
			delete(r.clientUUIDs, sessionInfo.ClientUUID)
		}
		log.Printf("Cleaned up expired session: %s", sessionID)
	}

	log.Printf("Cleaned up %d expired sessions", len(expiredSessions))
}

// GetSessionCount returns the number of active sessions
func (r *Registry) GetSessionCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.sessions)
}

// GetSessionInfo returns detailed session information
func (r *Registry) GetSessionInfo(sessionID string) (*SessionInfo, error) {
	r.mu.RLock()
	sessionInfo, exists := r.sessions[sessionID]
	r.mu.RUnlock()

	if exists {
		// Create a copy to avoid race conditions
		info := *sessionInfo
		return &info, nil
	}

	return nil, fmt.Errorf("session %s not found", sessionID)
}

// GenerateClientUUID generates a new client UUID
func GenerateClientUUID() string {
	return uuid.New().String()
}

// StartSessionMonitoring starts automatic session state monitoring
func (r *Registry) StartSessionMonitoring(gridManager GridManager, interval time.Duration) {
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

// GridManager interface for session monitoring
type GridManager interface {
	GetHealthyInstances() []InstanceStatus
	GetInstance(id string) (*InstanceStatus, error)
}

// InstanceStatus represents grid instance status for monitoring
type InstanceStatus struct {
	ID  string
	URL string
}

// monitorSessionStates checks if sessions still exist on their Grid instances
func (r *Registry) monitorSessionStates(gridManager GridManager) {
	r.mu.RLock()
	sessions := make([]*SessionInfo, 0, len(r.sessions))
	for _, session := range r.sessions {
		sessionCopy := *session
		sessions = append(sessions, &sessionCopy)
	}
	r.mu.RUnlock()

	for _, sessionInfo := range sessions {
		if r.verifySessionExists(sessionInfo, gridManager) {
			r.updateLastAccessed(sessionInfo.SessionID)
		} else {
			// Session no longer exists, remove from registry
			r.RemoveSession(sessionInfo.SessionID)
			log.Printf("Automatically removed stale session: %s", sessionInfo.SessionID)
		}
	}
}

// verifySessionExists checks if a session still exists on its Grid instance
func (r *Registry) verifySessionExists(sessionInfo *SessionInfo, gridManager GridManager) bool {
	instance, err := gridManager.GetInstance(sessionInfo.GridInstance)
	if err != nil {
		return false
	}
	
	return r.sessionExistsOnInstance(sessionInfo.SessionID, instance.URL)
}

// sessionExistsOnInstance checks if a session exists on a specific Grid instance
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

// DiscoverSessionsFromGrids automatically discovers sessions from Grid instances
func (r *Registry) DiscoverSessionsFromGrids(gridManager GridManager) {
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

// queryGridInstanceSessions queries a Grid instance for active sessions
func (r *Registry) queryGridInstanceSessions(gridURL string) ([]string, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(gridURL + "/status")
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
