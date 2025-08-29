package metrics

import (
	"fmt"
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// Request metrics
	RequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_requests_total",
			Help: "Total number of requests processed by the load balancer",
		},
		[]string{"method", "path", "status", "grid_instance"},
	)

	RequestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "loadbalancer_request_duration_seconds",
			Help:    "Request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path", "grid_instance"},
	)

	// Session metrics
	ActiveSessions = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "loadbalancer_active_sessions",
			Help: "Number of active sessions",
		},
	)

	SessionsCreated = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_sessions_created_total",
			Help: "Total number of sessions created",
		},
		[]string{"grid_instance"},
	)

	SessionsTerminated = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_sessions_terminated_total",
			Help: "Total number of sessions terminated",
		},
		[]string{"grid_instance", "reason"},
	)

	// Grid instance metrics
	GridInstancesHealthy = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "loadbalancer_grid_instances_healthy",
			Help: "Number of healthy grid instances",
		},
		[]string{"instance_id"},
	)

	GridInstanceResponseTime = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "loadbalancer_grid_instance_response_time_ms",
			Help: "Response time of grid instances in milliseconds",
		},
		[]string{"instance_id"},
	)

	GridInstanceErrors = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_grid_instance_errors_total",
			Help: "Total number of errors from grid instances",
		},
		[]string{"instance_id", "error_type"},
	)

	// Connection recovery metrics
	ConnectionRecoveries = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_connection_recoveries_total",
			Help: "Total number of connection recoveries",
		},
		[]string{"recovery_type"},
	)

	FailoverAttempts = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "loadbalancer_failover_attempts_total",
			Help: "Total number of failover attempts",
		},
		[]string{"from_instance", "to_instance", "success"},
	)
)

// init registers all metrics with Prometheus
func init() {
	prometheus.MustRegister(
		RequestsTotal,
		RequestDuration,
		ActiveSessions,
		SessionsCreated,
		SessionsTerminated,
		GridInstancesHealthy,
		GridInstanceResponseTime,
		GridInstanceErrors,
		ConnectionRecoveries,
		FailoverAttempts,
	)
}

// MetricsMiddleware wraps HTTP handlers to collect metrics
func MetricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Wrap the ResponseWriter to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		next.ServeHTTP(wrapped, r)
		
		duration := time.Since(start).Seconds()
		
		// Record metrics
		RequestsTotal.WithLabelValues(
			r.Method,
			r.URL.Path,
			http.StatusText(wrapped.statusCode),
			r.Header.Get("X-Grid-Instance"),
		).Inc()
		
		RequestDuration.WithLabelValues(
			r.Method,
			r.URL.Path,
			r.Header.Get("X-Grid-Instance"),
		).Observe(duration)
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// StartMetricsServer starts the Prometheus metrics server
func StartMetricsServer(port int) {
	http.Handle("/metrics", promhttp.Handler())
	go http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}

// UpdateSessionMetrics updates session-related metrics
func UpdateSessionMetrics(activeCount int) {
	ActiveSessions.Set(float64(activeCount))
}

// RecordSessionCreated records a new session creation
func RecordSessionCreated(gridInstance string) {
	SessionsCreated.WithLabelValues(gridInstance).Inc()
}

// RecordSessionTerminated records a session termination
func RecordSessionTerminated(gridInstance, reason string) {
	SessionsTerminated.WithLabelValues(gridInstance, reason).Inc()
}

// UpdateGridInstanceMetrics updates grid instance health metrics
func UpdateGridInstanceMetrics(instanceID string, healthy bool, responseTime int64) {
	if healthy {
		GridInstancesHealthy.WithLabelValues(instanceID).Set(1)
		GridInstanceResponseTime.WithLabelValues(instanceID).Set(float64(responseTime))
	} else {
		GridInstancesHealthy.WithLabelValues(instanceID).Set(0)
	}
}

// RecordGridInstanceError records an error from a grid instance
func RecordGridInstanceError(instanceID, errorType string) {
	GridInstanceErrors.WithLabelValues(instanceID, errorType).Inc()
}

// RecordConnectionRecovery records a connection recovery event
func RecordConnectionRecovery(recoveryType string) {
	ConnectionRecoveries.WithLabelValues(recoveryType).Inc()
}

// RecordFailoverAttempt records a failover attempt
func RecordFailoverAttempt(fromInstance, toInstance string, success bool) {
	successStr := "false"
	if success {
		successStr = "true"
	}
	FailoverAttempts.WithLabelValues(fromInstance, toInstance, successStr).Inc()
}
