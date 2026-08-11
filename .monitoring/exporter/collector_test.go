package main

import (
	"encoding/json"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
	dto "github.com/prometheus/client_model/go"
	"net/http"
	"net/http/httptest"
)

// ── test helpers ──────────────────────────────────────────────────────────────

func encode(t *testing.T, v any) string {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	return string(b)
}

// swapServer serves a body that the test can change between scrapes, so a single
// collector can be driven through a multi-scrape lifecycle.
type swapServer struct {
	mu   sync.Mutex
	body string
	srv  *httptest.Server
}

func newSwapServer(initial string) *swapServer {
	s := &swapServer{body: initial}
	s.srv = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s.mu.Lock()
		body := s.body
		s.mu.Unlock()
		_, _ = w.Write([]byte(body))
	}))
	return s
}

func (s *swapServer) set(body string) {
	s.mu.Lock()
	s.body = body
	s.mu.Unlock()
}

func (s *swapServer) close() { s.srv.Close() }

// chromeSession is the canonical active session used across the collector tests.
// startTime 02/01/2020 10:00:00 UTC == unix 1577959200.
func chromeSession(t *testing.T) sessionEntry {
	return sessionEntry{
		ID:                    "s1",
		Capabilities:          encode(t, caps{BrowserName: "chrome", BrowserVersion: "124", PlatformName: "linux", TestName: "login-test", ContainerName: "node-chrome-1"}),
		StartTime:             "02/01/2020 10:00:00",
		SessionDurationMillis: "42300",
		NodeID:                "node-up",
		NodeURI:               "http://node1:5555",
	}
}

const chromeSessionStartUnix = 1577959200

// gridResponse renders a full GraphQL data envelope with the given sessions and
// queue. Two nodes are always present: one UP (chrome), one DRAINING (firefox).
func gridResponse(t *testing.T, sessions []sessionEntry, queue []string) string {
	t.Helper()
	chromeStereo := encode(t, []stereotypeEntry{{Stereotype: caps{BrowserName: "chrome", BrowserVersion: "124", PlatformName: "linux"}, Slots: 4}})
	firefoxStereo := encode(t, []stereotypeEntry{{Stereotype: caps{BrowserName: "firefox", BrowserVersion: "125", PlatformName: "linux"}, Slots: 4}})

	resp := gqlResponse{Data: &gridData{
		Grid: gridSummary{
			URI: "http://hub:4444", TotalSlots: 8, NodeCount: 2, MaxSession: 8,
			SessionCount: len(sessions), SessionQueueSize: len(queue), Version: "4.47.0",
		},
		NodesInfo: nodesInfo{Nodes: []nodeInfo{
			{ID: "node-up", URI: "http://node1:5555", Status: "UP", MaxSession: 4, SlotCount: 4, SessionCount: 1, Stereotypes: chromeStereo, Version: "4.47.0", OsInfo: osInfo{Arch: "arm64", Name: "Linux", Version: "6.1"}},
			{ID: "node-draining", URI: "http://node2:5555", Status: "DRAINING", MaxSession: 4, SlotCount: 4, SessionCount: 0, Stereotypes: firefoxStereo, Version: "4.47.0", OsInfo: osInfo{Arch: "amd64", Name: "Linux", Version: "5.15"}},
		}},
		SessionsInfo: sessionsInfo{SessionQueueRequests: queue, Sessions: sessions},
	}}
	return encode(t, resp)
}

// newTestCollector wires a collector to a swappable server and registers it on a
// pedantic registry so Gather() performs one scrape per call.
func newTestCollector(t *testing.T, initialBody string, retainFor time.Duration) (*collector, *swapServer, *prometheus.Registry) {
	t.Helper()
	s := newSwapServer(initialBody)
	t.Cleanup(s.close)

	client := newGridClient(s.srv.URL, "", "", 5*time.Second)
	c := newCollector(client, 5*time.Second, time.UTC, retainFor)

	reg := prometheus.NewPedanticRegistry()
	reg.MustRegister(c)
	return c, s, reg
}

func gather(t *testing.T, reg *prometheus.Registry) []*dto.MetricFamily {
	t.Helper()
	mfs, err := reg.Gather()
	if err != nil {
		t.Fatalf("gather: %v", err)
	}
	return mfs
}

// scalar returns the value of an unlabeled single-series metric family.
func scalar(t *testing.T, mfs []*dto.MetricFamily, name string) float64 {
	t.Helper()
	for _, mf := range mfs {
		if mf.GetName() != name {
			continue
		}
		if len(mf.GetMetric()) != 1 {
			t.Fatalf("%s: expected 1 series, got %d", name, len(mf.GetMetric()))
		}
		return metricValue(mf.GetMetric()[0])
	}
	t.Fatalf("metric %s not found", name)
	return 0
}

// series finds a metric within a family matching all the given labels.
func series(mfs []*dto.MetricFamily, name string, labels map[string]string) (*dto.Metric, bool) {
	for _, mf := range mfs {
		if mf.GetName() != name {
			continue
		}
		for _, m := range mf.GetMetric() {
			got := map[string]string{}
			for _, lp := range m.GetLabel() {
				got[lp.GetName()] = lp.GetValue()
			}
			match := true
			for k, v := range labels {
				if got[k] != v {
					match = false
					break
				}
			}
			if match {
				return m, true
			}
		}
	}
	return nil, false
}

func metricValue(m *dto.Metric) float64 {
	if m.GetGauge() != nil {
		return m.GetGauge().GetValue()
	}
	if m.GetCounter() != nil {
		return m.GetCounter().GetValue()
	}
	return 0
}

// ── tests ─────────────────────────────────────────────────────────────────────

func TestCollectorDescribe(t *testing.T) {
	c := newCollector(nil, time.Second, time.UTC, time.Minute)
	ch := make(chan *prometheus.Desc, 64)
	c.Describe(ch)
	close(ch)

	const want = 20 // every metric the collector can emit must be described
	if got := len(ch); got != want {
		t.Errorf("Describe emitted %d descriptors, want %d", got, want)
	}
}

func TestCollectScrapeFailure(t *testing.T) {
	// Point the collector at a closed server so the scrape errors out.
	s := newSwapServer("")
	url := s.srv.URL
	s.close()

	client := newGridClient(url, "", "", time.Second)
	c := newCollector(client, time.Second, time.UTC, time.Minute)
	reg := prometheus.NewPedanticRegistry()
	reg.MustRegister(c)

	// Health must always be emitted, reporting failure.
	expected := `
# HELP selenium_grid_scrape_success 1 if the last scrape of the Grid GraphQL endpoint succeeded, 0 otherwise.
# TYPE selenium_grid_scrape_success gauge
selenium_grid_scrape_success 0
`
	if err := testutil.CollectAndCompare(c, strings.NewReader(expected), "selenium_grid_scrape_success"); err != nil {
		t.Errorf("scrape_success mismatch: %v", err)
	}
	// No grid data must be emitted when the scrape fails.
	if n := testutil.CollectAndCount(c, "selenium_grid_total_slots"); n != 0 {
		t.Errorf("expected no grid metrics on failure, got %d total_slots series", n)
	}
}

func TestCollectFullSnapshot(t *testing.T) {
	queue := []string{encode(t, map[string]string{"browserName": "chrome", "browserVersion": "124", "platformName": "linux"})}
	body := gridResponse(t, []sessionEntry{chromeSession(t)}, queue)
	_, _, reg := newTestCollector(t, body, time.Minute)

	mfs := gather(t, reg)

	// Node status score mapping (UP=1, DRAINING=0.5) with the full label set.
	if m, ok := series(mfs, "selenium_grid_node_status", map[string]string{
		"node_id": "node-up", "uri": "http://node1:5555", "version": "4.47.0",
		"os_name": "Linux", "os_arch": "arm64", "os_version": "6.1",
	}); !ok {
		t.Error("node_status{node-up} missing or labels wrong")
	} else if v := metricValue(m); v != 1 {
		t.Errorf("node-up status = %v, want 1 (UP)", v)
	}
	if m, ok := series(mfs, "selenium_grid_node_status", map[string]string{
		"node_id": "node-draining", "uri": "http://node2:5555", "version": "4.47.0",
		"os_name": "Linux", "os_arch": "amd64", "os_version": "5.15",
	}); !ok {
		t.Error("node_status{node-draining} missing or labels wrong")
	} else if v := metricValue(m); v != 0.5 {
		t.Errorf("node-draining status = %v, want 0.5 (DRAINING)", v)
	}

	// Stereotype slots are broken out per (node, browser, version, platform).
	if m, ok := series(mfs, "selenium_grid_node_stereotype_slots_total", map[string]string{
		"node_id": "node-up", "browser_name": "chrome", "browser_version": "124", "platform_name": "linux",
	}); !ok {
		t.Error("stereotype_slots{node-up,chrome} missing")
	} else if v := metricValue(m); v != 4 {
		t.Errorf("stereotype_slots = %v, want 4", v)
	}
	if _, ok := series(mfs, "selenium_grid_node_stereotype_slots_total", map[string]string{
		"node_id": "node-draining", "browser_name": "firefox", "browser_version": "125", "platform_name": "linux",
	}); !ok {
		t.Error("stereotype_slots{node-draining,firefox} missing")
	}
	checks := map[string]float64{
		"selenium_grid_scrape_success":     1,
		"selenium_grid_total_slots":        8,
		"selenium_grid_node_count":         2,
		"selenium_grid_max_sessions":       8,
		"selenium_grid_session_count":      1,
		"selenium_grid_session_queue_size": 1,
		"selenium_grid_sessions_completed_total": 0,
	}
	for name, want := range checks {
		if got := scalar(t, mfs, name); got != want {
			t.Errorf("%s = %v, want %v", name, got, want)
		}
	}

	capLabels := map[string]string{"browser_name": "chrome", "browser_version": "124", "platform_name": "linux"}
	if m, ok := series(mfs, "selenium_grid_sessions_active", capLabels); !ok {
		t.Error("selenium_grid_sessions_active{chrome} missing")
	} else if v := metricValue(m); v != 1 {
		t.Errorf("sessions_active = %v, want 1", v)
	}
	if m, ok := series(mfs, "selenium_grid_session_queue_requests", capLabels); !ok {
		t.Error("selenium_grid_session_queue_requests{chrome} missing")
	} else if v := metricValue(m); v != 1 {
		t.Errorf("session_queue_requests = %v, want 1", v)
	}

	sessLabels := map[string]string{"session_id": "s1", "test_name": "login-test", "container_name": "node-chrome-1"}
	if m, ok := series(mfs, "selenium_grid_session_start_seconds", sessLabels); !ok {
		t.Error("selenium_grid_session_start_seconds{s1} missing")
	} else if v := metricValue(m); v != chromeSessionStartUnix {
		t.Errorf("session_start_seconds = %v, want %d", v, chromeSessionStartUnix)
	}
	if m, ok := series(mfs, "selenium_grid_session_duration_seconds", sessLabels); !ok {
		t.Error("selenium_grid_session_duration_seconds{s1} missing")
	} else if v := metricValue(m); v != 42.3 {
		t.Errorf("session_duration_seconds = %v, want 42.3", v)
	}
}

func TestSessionLifecycle(t *testing.T) {
	// retainFor = 0 so a stopped session is pruned on the scrape after the one
	// that recorded its stop.
	body1 := gridResponse(t, []sessionEntry{chromeSession(t)}, nil)
	c, s, reg := newTestCollector(t, body1, 0)
	_ = c

	sessLabels := map[string]string{"session_id": "s1"}

	// Scrape 1: session active — start recorded, no stop, nothing completed yet.
	mfs := gather(t, reg)
	if v := scalar(t, mfs, "selenium_grid_sessions_completed_total"); v != 0 {
		t.Errorf("after scrape 1 completed = %v, want 0", v)
	}
	if _, ok := series(mfs, "selenium_grid_session_start_seconds", sessLabels); !ok {
		t.Error("start_seconds missing while session active")
	}
	if _, ok := series(mfs, "selenium_grid_session_stop_seconds", sessLabels); ok {
		t.Error("stop_seconds present while session still active")
	}

	// Scrape 2: session gone — stop recorded, completed counter increments.
	s.set(gridResponse(t, nil, nil))
	mfs = gather(t, reg)
	if v := scalar(t, mfs, "selenium_grid_sessions_completed_total"); v != 1 {
		t.Errorf("after scrape 2 completed = %v, want 1", v)
	}
	stop, ok := series(mfs, "selenium_grid_session_stop_seconds", sessLabels)
	if !ok {
		t.Fatal("stop_seconds missing after session ended")
	}
	if metricValue(stop) <= 0 {
		t.Errorf("stop_seconds = %v, want > 0", metricValue(stop))
	}
	if _, ok := series(mfs, "selenium_grid_session_start_seconds", sessLabels); !ok {
		t.Error("start_seconds should still be retained on the stop scrape")
	}

	// Scrape 3: retention window (0) elapsed — stopped session pruned, but the
	// completed counter is monotonic and must hold.
	mfs = gather(t, reg)
	if v := scalar(t, mfs, "selenium_grid_sessions_completed_total"); v != 1 {
		t.Errorf("after scrape 3 completed = %v, want 1 (monotonic)", v)
	}
	if _, ok := series(mfs, "selenium_grid_session_stop_seconds", sessLabels); ok {
		t.Error("stop_seconds should be pruned after the retention window")
	}
}

func TestSessionDurationFallback(t *testing.T) {
	// Grid hasn't reported a duration yet (0 millis); the collector must fall
	// back to wall-clock using the parsed startTime.
	s := chromeSession(t)
	s.SessionDurationMillis = "0"
	c, _, reg := newTestCollector(t, gridResponse(t, []sessionEntry{s}, nil), time.Minute)
	_ = c

	mfs := gather(t, reg)
	m, ok := series(mfs, "selenium_grid_session_duration_seconds", map[string]string{"session_id": "s1"})
	if !ok {
		t.Fatal("session_duration_seconds{s1} missing")
	}
	// startTime is in 2020, so wall-clock duration is a large positive number.
	if v := metricValue(m); v <= 0 {
		t.Errorf("fallback duration = %v, want > 0", v)
	}
}

func TestNodeDeregistration(t *testing.T) {
	c, s, reg := newTestCollector(t, gridResponse(t, nil, nil), time.Minute)
	_ = c

	mfs := gather(t, reg)
	if _, ok := series(mfs, "selenium_grid_node_status", map[string]string{"node_id": "node-draining"}); !ok {
		t.Fatal("node-draining should be present on scrape 1")
	}

	// Grid now reports only node-up; node-draining has de-registered.
	onlyUp := `{"data":{"grid":{"nodeCount":1,"totalSlots":4,"version":"4.47.0"},` +
		`"nodesInfo":{"nodes":[{"id":"node-up","uri":"http://node1:5555","status":"UP","maxSession":4,"slotCount":4,"sessionCount":0,"stereotypes":"[]","version":"4.47.0","osInfo":{"arch":"arm64","name":"Linux","version":"6.1"}}]},` +
		`"sessionsInfo":{"sessionQueueRequests":[],"sessions":[]}}}`
	s.set(onlyUp)

	mfs = gather(t, reg)
	if _, ok := series(mfs, "selenium_grid_node_status", map[string]string{"node_id": "node-up"}); !ok {
		t.Error("node-up should still be present after scrape 2")
	}
	if _, ok := series(mfs, "selenium_grid_node_status", map[string]string{"node_id": "node-draining"}); ok {
		t.Error("node-draining should be dropped after it de-registers")
	}
}

func TestNodeStatusScoreTransition(t *testing.T) {
	// node-up is UP on scrape 1, then flips to DRAINING on scrape 2.
	c, s, reg := newTestCollector(t, gridResponse(t, nil, nil), time.Minute)
	_ = c

	upLabels := map[string]string{"node_id": "node-up"}

	mfs := gather(t, reg)
	if m, ok := series(mfs, "selenium_grid_node_status", upLabels); !ok {
		t.Fatal("node_status{node-up} missing")
	} else if v := metricValue(m); v != 1 {
		t.Errorf("node-up status = %v, want 1 (UP)", v)
	}
	// status_duration is reported against the current status label.
	if _, ok := series(mfs, "selenium_grid_node_status_duration_seconds",
		map[string]string{"node_id": "node-up", "status": "UP"}); !ok {
		t.Error("node_status_duration{node-up,UP} missing on scrape 1")
	}

	// Flip node-up to DRAINING.
	flipped := strings.Replace(gridResponse(t, nil, nil),
		`"id":"node-up","uri":"http://node1:5555","status":"UP"`,
		`"id":"node-up","uri":"http://node1:5555","status":"DRAINING"`, 1)
	if flipped == gridResponse(t, nil, nil) {
		t.Fatal("test setup: status replacement did not match the response body")
	}
	s.set(flipped)

	mfs = gather(t, reg)
	if m, ok := series(mfs, "selenium_grid_node_status", upLabels); !ok {
		t.Fatal("node_status{node-up} missing after flip")
	} else if v := metricValue(m); v != 0.5 {
		t.Errorf("node-up status = %v, want 0.5 (DRAINING)", v)
	}
	// The duration must now be tracked against DRAINING (clock reset on change).
	if _, ok := series(mfs, "selenium_grid_node_status_duration_seconds",
		map[string]string{"node_id": "node-up", "status": "DRAINING"}); !ok {
		t.Error("node_status_duration{node-up,DRAINING} missing after status change")
	}
}
