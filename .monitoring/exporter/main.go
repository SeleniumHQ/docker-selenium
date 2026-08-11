package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// defaultEndpoint constructs the GraphQL URL from Hub/Router container env vars.
// SE_SUB_PATH may be empty, "/", "/selenium", or "/selenium/" — all normalised
// to a single clean path prefix with no trailing slash before appending /graphql.
func defaultEndpoint() string {
	protocol := os.Getenv("SE_SERVER_PROTOCOL")
	if protocol == "" {
		protocol = "http"
	}
	port := os.Getenv("SE_ROUTER_PORT")
	if port == "" {
		port = "4444"
	}
	subPath := strings.TrimRight(os.Getenv("SE_SUB_PATH"), "/")
	return fmt.Sprintf("%s://localhost:%s%s/graphql", protocol, port, subPath)
}

// config holds the resolved runtime settings for the exporter.
type config struct {
	gridURL       string
	listenAddr    string
	scrapeTimeout time.Duration
	metricsPath   string
	gridTimezone  string
	retainStopped time.Duration
	username      string
	password      string
}

// parseFlags resolves the exporter configuration from command-line args, falling
// back to the Hub/Router environment variables for defaults. It uses a dedicated
// FlagSet (rather than the global one) so it is safe to call from tests.
func parseFlags(name string, args []string) (config, error) {
	defaultTZ := os.Getenv("TZ")
	if defaultTZ == "" {
		defaultTZ = "UTC"
	}

	fs := flag.NewFlagSet(name, flag.ContinueOnError)
	var cfg config
	fs.StringVar(&cfg.gridURL, "grid-url", defaultEndpoint(), "Selenium Grid GraphQL endpoint; defaults to $SE_SERVER_PROTOCOL://localhost:$SE_ROUTER_PORT/$SE_SUB_PATH/graphql")
	fs.StringVar(&cfg.listenAddr, "listen-address", ":9615", "Address to expose /metrics on")
	fs.DurationVar(&cfg.scrapeTimeout, "scrape-timeout", 10*time.Second, "Timeout for each GraphQL scrape")
	fs.StringVar(&cfg.metricsPath, "metrics-path", "/metrics", "Path under which to expose metrics")
	fs.StringVar(&cfg.gridTimezone, "grid-timezone", defaultTZ, "Timezone of the Grid server (used to parse session startTime, e.g. Asia/Ho_Chi_Minh); defaults to $TZ")
	fs.DurationVar(&cfg.retainStopped, "retain-stopped", 5*time.Minute, "How long to keep start/stop metrics for ended sessions")
	fs.StringVar(&cfg.username, "username", os.Getenv("SE_ROUTER_USERNAME"), "Grid basic-auth username; defaults to $SE_ROUTER_USERNAME")
	fs.StringVar(&cfg.password, "password", os.Getenv("SE_ROUTER_PASSWORD"), "Grid basic-auth password; defaults to $SE_ROUTER_PASSWORD")

	if err := fs.Parse(args); err != nil {
		return config{}, err
	}
	return cfg, nil
}

// newServer wires the collector, registry, and HTTP handlers into an
// http.Server. It returns an error for invalid configuration (e.g. an unknown
// timezone) so the caller can decide how to fail.
func newServer(cfg config) (*http.Server, error) {
	loc, err := time.LoadLocation(cfg.gridTimezone)
	if err != nil {
		return nil, fmt.Errorf("invalid -grid-timezone %q: %w", cfg.gridTimezone, err)
	}

	client := newGridClient(cfg.gridURL, cfg.username, cfg.password, cfg.scrapeTimeout)
	col := newCollector(client, cfg.scrapeTimeout, loc, cfg.retainStopped)

	reg := prometheus.NewRegistry()
	reg.MustRegister(col)

	mux := http.NewServeMux()
	mux.Handle(cfg.metricsPath, promhttp.HandlerFor(reg, promhttp.HandlerOpts{
		ErrorHandling: promhttp.ContinueOnError,
	}))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`<html><head><title>Selenium Grid Exporter</title></head>
<body><h1>Selenium Grid Exporter</h1>
<p><a href="` + cfg.metricsPath + `">Metrics</a></p></body></html>`))
	})

	return &http.Server{Addr: cfg.listenAddr, Handler: mux}, nil
}

func main() {
	cfg, err := parseFlags(os.Args[0], os.Args[1:])
	if err != nil {
		log.Fatalf("parse flags: %v", err)
	}

	srv, err := newServer(cfg)
	if err != nil {
		log.Fatalf("%v", err)
	}

	log.Printf("selenium-grid-exporter listening on %s (grid: %s, tz: %s)", cfg.listenAddr, cfg.gridURL, cfg.gridTimezone)
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("listen: %v", err)
	}
}
