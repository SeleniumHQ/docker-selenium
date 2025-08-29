package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/selenium/go-grid-loadbalancer/config"
	"github.com/selenium/go-grid-loadbalancer/grid"
	"github.com/selenium/go-grid-loadbalancer/metrics"
	"github.com/selenium/go-grid-loadbalancer/proxy"
	"github.com/selenium/go-grid-loadbalancer/session"
)

func main() {
	// Parse command line flags
	configFile := flag.String("config", "config.yaml", "Path to configuration file")
	flag.Parse()

	// Load configuration
	cfg, err := config.LoadConfig(*configFile)
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	log.Printf("Starting Selenium Grid Load Balancer on port %d", cfg.LoadBalancer.Port)
	log.Printf("Health check interval: %v", cfg.LoadBalancer.HealthCheckInterval)
	log.Printf("Session timeout: %v", cfg.LoadBalancer.SessionTimeout)
	log.Printf("Redis enabled: %v", cfg.Redis.Enabled)

	// Initialize session registry
	sessionRegistry := session.NewRegistry(
		cfg.Redis.Enabled,
		cfg.Redis.Host,
		cfg.Redis.Port,
		cfg.Redis.Password,
		cfg.Redis.DB,
		time.Duration(cfg.Redis.KeyTTL)*time.Second,
	)

	// Initialize grid manager
	gridManager := grid.NewManager(cfg)

	// Start health checking
	gridManager.StartHealthChecking()
	log.Printf("Started health checking for %d grid instances", len(cfg.GetEnabledGridInstances()))

	// Initialize automatic session tracker
	sessionTracker := session.NewAutomaticSessionTracker(sessionRegistry, gridManager)
	
	// Start automatic session tracking
	monitoringInterval := 30 * time.Second
	discoveryInterval := 2 * time.Minute
	sessionTracker.Start(monitoringInterval, discoveryInterval)
	log.Printf("Started automatic session tracking (monitoring: %v, discovery: %v)", monitoringInterval, discoveryInterval)

	// Initialize HTTP router
	router := proxy.NewRouter(sessionRegistry, gridManager, cfg)

	// Start metrics server if enabled
	if cfg.Monitoring.Enabled {
		metrics.StartMetricsServer(cfg.Monitoring.MetricsPort)
		log.Printf("Started metrics server on port %d", cfg.Monitoring.MetricsPort)
	}

	// Start session cleanup routine
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		
		for {
			select {
			case <-ticker.C:
				sessionRegistry.CleanupExpiredSessions(cfg.LoadBalancer.SessionTimeout)
				// Update metrics
				if cfg.Monitoring.Enabled {
					metrics.UpdateSessionMetrics(sessionRegistry.GetSessionCount())
				}
			}
		}
	}()

	// Create HTTP server
	var handler http.Handler = router
	if cfg.LoadBalancer.EnableMetrics {
		handler = metrics.MetricsMiddleware(router)
	}

	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.LoadBalancer.Port),
		Handler:      handler,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 300 * time.Second, // Long timeout for WebDriver operations
		IdleTimeout:  120 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("Load balancer listening on :%d", cfg.LoadBalancer.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down load balancer...")

	// Create a deadline to wait for
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Attempt graceful shutdown
	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
	}

	log.Println("Load balancer stopped")
}
