package config

import (
	"fmt"
	"io/ioutil"
	"time"

	"gopkg.in/yaml.v2"
)

// Config represents the load balancer configuration
type Config struct {
	LoadBalancer LoadBalancerConfig `yaml:"loadbalancer"`
	GridInstances []GridInstance    `yaml:"grid_instances"`
	Redis        RedisConfig        `yaml:"redis"`
	Monitoring   MonitoringConfig   `yaml:"monitoring"`
}

// LoadBalancerConfig contains load balancer specific settings
type LoadBalancerConfig struct {
	Port                int           `yaml:"port"`
	HealthCheckInterval time.Duration `yaml:"health_check_interval"`
	SessionTimeout      time.Duration `yaml:"session_timeout"`
	MaxRetries          int           `yaml:"max_retries"`
	RetryInterval       time.Duration `yaml:"retry_interval"`
	EnableMetrics       bool          `yaml:"enable_metrics"`
	Strategy            string        `yaml:"strategy"`              // Load balancing strategy
}

// GridInstance represents a Selenium Grid instance
type GridInstance struct {
	ID          string `yaml:"id"`
	URL         string `yaml:"url"`
	Priority    int    `yaml:"priority"`
	Weight      int    `yaml:"weight"`
	Enabled     bool   `yaml:"enabled"`
	Username    string `yaml:"username,omitempty"`    // Optional basic auth username
	Password    string `yaml:"password,omitempty"`    // Optional basic auth password
	MaxSessions int    `yaml:"max_sessions,omitempty"` // Maximum sessions for Greedy strategy
	Region      string `yaml:"region,omitempty"`      // Geographic region for HA GEO
	Role        string `yaml:"role,omitempty"`        // Role: "active" or "standby" for HA GEO
}

// RedisConfig contains Redis connection settings
type RedisConfig struct {
	Enabled  bool   `yaml:"enabled"`
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Password string `yaml:"password"`
	DB       int    `yaml:"db"`
	KeyTTL   int    `yaml:"key_ttl"`
}

// MonitoringConfig contains monitoring and metrics settings
type MonitoringConfig struct {
	Enabled    bool `yaml:"enabled"`
	MetricsPort int  `yaml:"metrics_port"`
}

// LoadConfig loads configuration from a YAML file
func LoadConfig(filename string) (*Config, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Set defaults
	if config.LoadBalancer.Port == 0 {
		config.LoadBalancer.Port = 4444
	}
	if config.LoadBalancer.HealthCheckInterval == 0 {
		config.LoadBalancer.HealthCheckInterval = 30 * time.Second
	}
	if config.LoadBalancer.SessionTimeout == 0 {
		config.LoadBalancer.SessionTimeout = 300 * time.Second
	}
	if config.LoadBalancer.MaxRetries == 0 {
		config.LoadBalancer.MaxRetries = 3
	}
	if config.LoadBalancer.RetryInterval == 0 {
		config.LoadBalancer.RetryInterval = 5 * time.Second
	}
	if config.LoadBalancer.Strategy == "" {
		config.LoadBalancer.Strategy = "weighted_round_robin"
	}

	return &config, nil
}

// GetEnabledGridInstances returns only enabled grid instances
func (c *Config) GetEnabledGridInstances() []GridInstance {
	var enabled []GridInstance
	for _, instance := range c.GridInstances {
		if instance.Enabled {
			enabled = append(enabled, instance)
		}
	}
	return enabled
}
