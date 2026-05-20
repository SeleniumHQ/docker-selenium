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

func main() {
	defaultTZ := os.Getenv("TZ")
	if defaultTZ == "" {
		defaultTZ = "UTC"
	}

	var (
		gridURL       = flag.String("grid-url", defaultEndpoint(), "Selenium Grid GraphQL endpoint; defaults to $SE_SERVER_PROTOCOL://localhost:$SE_ROUTER_PORT/$SE_SUB_PATH/graphql")
		listenAddr    = flag.String("listen-address", ":9615", "Address to expose /metrics on")
		scrapeTimeout = flag.Duration("scrape-timeout", 10*time.Second, "Timeout for each GraphQL scrape")
		metricsPath   = flag.String("metrics-path", "/metrics", "Path under which to expose metrics")
		gridTimezone  = flag.String("grid-timezone", defaultTZ, "Timezone of the Grid server (used to parse session startTime, e.g. Asia/Ho_Chi_Minh); defaults to $TZ")
		retainStopped = flag.Duration("retain-stopped", 5*time.Minute, "How long to keep start/stop metrics for ended sessions")
		username      = flag.String("username", os.Getenv("SE_ROUTER_USERNAME"), "Grid basic-auth username; defaults to $SE_ROUTER_USERNAME")
		password      = flag.String("password", os.Getenv("SE_ROUTER_PASSWORD"), "Grid basic-auth password; defaults to $SE_ROUTER_PASSWORD")
	)
	flag.Parse()

	loc, err := time.LoadLocation(*gridTimezone)
	if err != nil {
		log.Fatalf("invalid -grid-timezone %q: %v", *gridTimezone, err)
	}

	client := newGridClient(*gridURL, *username, *password, *scrapeTimeout)
	col := newCollector(client, *scrapeTimeout, loc, *retainStopped)

	reg := prometheus.NewRegistry()
	reg.MustRegister(col)

	mux := http.NewServeMux()
	mux.Handle(*metricsPath, promhttp.HandlerFor(reg, promhttp.HandlerOpts{
		ErrorHandling: promhttp.ContinueOnError,
	}))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte(`<html><head><title>Selenium Grid Exporter</title></head>
<body><h1>Selenium Grid Exporter</h1>
<p><a href="` + *metricsPath + `">Metrics</a></p></body></html>`))
	})

	log.Printf("selenium-grid-exporter listening on %s (grid: %s, tz: %s)", *listenAddr, *gridURL, loc)
	if err := http.ListenAndServe(*listenAddr, mux); err != nil {
		log.Fatalf("listen: %v", err)
	}
}
