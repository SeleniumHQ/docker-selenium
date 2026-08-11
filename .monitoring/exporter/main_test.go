package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestDefaultEndpoint(t *testing.T) {
	tests := []struct {
		name     string
		protocol string
		port     string
		subPath  string
		want     string
	}{
		{
			name: "all defaults",
			want: "http://localhost:4444/graphql",
		},
		{
			name:     "custom protocol and port",
			protocol: "https",
			port:     "443",
			want:     "https://localhost:443/graphql",
		},
		{
			name:    "sub path with leading slash",
			subPath: "/selenium",
			want:    "http://localhost:4444/selenium/graphql",
		},
		{
			name:    "sub path with trailing slash is trimmed",
			subPath: "/selenium/",
			want:    "http://localhost:4444/selenium/graphql",
		},
		{
			name:    "bare slash sub path collapses cleanly",
			subPath: "/",
			want:    "http://localhost:4444/graphql",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// t.Setenv both sets the value and restores the prior one on cleanup,
			// so each case runs with a known, isolated environment.
			t.Setenv("SE_SERVER_PROTOCOL", tt.protocol)
			t.Setenv("SE_ROUTER_PORT", tt.port)
			t.Setenv("SE_SUB_PATH", tt.subPath)

			if got := defaultEndpoint(); got != tt.want {
				t.Errorf("defaultEndpoint() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestParseFlagsDefaults(t *testing.T) {
	// Clear the env so defaults are deterministic.
	for _, k := range []string{"TZ", "SE_SERVER_PROTOCOL", "SE_ROUTER_PORT", "SE_SUB_PATH", "SE_ROUTER_USERNAME", "SE_ROUTER_PASSWORD"} {
		t.Setenv(k, "")
	}

	cfg, err := parseFlags("exporter", nil)
	if err != nil {
		t.Fatalf("parseFlags: %v", err)
	}
	if cfg.listenAddr != ":9615" {
		t.Errorf("listenAddr = %q, want :9615", cfg.listenAddr)
	}
	if cfg.metricsPath != "/metrics" {
		t.Errorf("metricsPath = %q, want /metrics", cfg.metricsPath)
	}
	if cfg.scrapeTimeout != 10*time.Second {
		t.Errorf("scrapeTimeout = %v, want 10s", cfg.scrapeTimeout)
	}
	if cfg.retainStopped != 5*time.Minute {
		t.Errorf("retainStopped = %v, want 5m", cfg.retainStopped)
	}
	if cfg.gridTimezone != "UTC" {
		t.Errorf("gridTimezone = %q, want UTC (fallback when $TZ unset)", cfg.gridTimezone)
	}
	if cfg.gridURL != "http://localhost:4444/graphql" {
		t.Errorf("gridURL = %q, unexpected default", cfg.gridURL)
	}
}

func TestParseFlagsOverrides(t *testing.T) {
	t.Setenv("TZ", "")
	args := []string{
		"-grid-url", "https://hub:4444/selenium/graphql",
		"-listen-address", ":8080",
		"-scrape-timeout", "3s",
		"-metrics-path", "/m",
		"-grid-timezone", "Asia/Ho_Chi_Minh",
		"-retain-stopped", "1m",
		"-username", "admin",
		"-password", "secret",
	}
	cfg, err := parseFlags("exporter", args)
	if err != nil {
		t.Fatalf("parseFlags: %v", err)
	}
	want := config{
		gridURL:       "https://hub:4444/selenium/graphql",
		listenAddr:    ":8080",
		scrapeTimeout: 3 * time.Second,
		metricsPath:   "/m",
		gridTimezone:  "Asia/Ho_Chi_Minh",
		retainStopped: time.Minute,
		username:      "admin",
		password:      "secret",
	}
	if cfg != want {
		t.Errorf("parseFlags() = %+v, want %+v", cfg, want)
	}
}

func TestParseFlagsEnvDefaults(t *testing.T) {
	t.Setenv("TZ", "Europe/Berlin")
	t.Setenv("SE_ROUTER_USERNAME", "envuser")
	t.Setenv("SE_ROUTER_PASSWORD", "envpass")

	cfg, err := parseFlags("exporter", nil)
	if err != nil {
		t.Fatalf("parseFlags: %v", err)
	}
	if cfg.gridTimezone != "Europe/Berlin" {
		t.Errorf("gridTimezone = %q, want Europe/Berlin from $TZ", cfg.gridTimezone)
	}
	if cfg.username != "envuser" || cfg.password != "envpass" {
		t.Errorf("credentials = (%q,%q), want env defaults", cfg.username, cfg.password)
	}
}

func TestParseFlagsInvalid(t *testing.T) {
	if _, err := parseFlags("exporter", []string{"-scrape-timeout", "not-a-duration"}); err == nil {
		t.Error("expected error for invalid duration flag, got nil")
	}
}

func TestNewServerInvalidTimezone(t *testing.T) {
	_, err := newServer(config{gridTimezone: "Not/AZone", metricsPath: "/metrics"})
	if err == nil {
		t.Fatal("expected error for invalid timezone, got nil")
	}
	if !strings.Contains(err.Error(), "grid-timezone") {
		t.Errorf("error = %q, want it to mention grid-timezone", err.Error())
	}
}

func TestNewServerHandlers(t *testing.T) {
	srv, err := newServer(config{
		gridURL:       "http://127.0.0.1:0/graphql", // unreachable; landing page needs no scrape
		listenAddr:    ":0",
		scrapeTimeout: time.Second,
		metricsPath:   "/metrics",
		gridTimezone:  "UTC",
		retainStopped: time.Minute,
	})
	if err != nil {
		t.Fatalf("newServer: %v", err)
	}
	if srv.Addr != ":0" {
		t.Errorf("server Addr = %q, want :0", srv.Addr)
	}

	// Landing page links to the metrics path.
	rec := httptest.NewRecorder()
	srv.Handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))
	if rec.Code != http.StatusOK {
		t.Errorf("landing page status = %d, want 200", rec.Code)
	}
	body, _ := io.ReadAll(rec.Result().Body)
	if !strings.Contains(string(body), `href="/metrics"`) {
		t.Errorf("landing page missing metrics link: %s", body)
	}

	// The metrics endpoint is registered and exposes exporter health even when
	// the Grid is unreachable (scrape_success 0).
	rec = httptest.NewRecorder()
	srv.Handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/metrics", nil))
	if rec.Code != http.StatusOK {
		t.Errorf("metrics status = %d, want 200", rec.Code)
	}
	metrics, _ := io.ReadAll(rec.Result().Body)
	if !strings.Contains(string(metrics), "selenium_grid_scrape_success") {
		t.Errorf("metrics output missing scrape_success: %s", metrics)
	}
}
