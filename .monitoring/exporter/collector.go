package main

import (
	"context"
	"log"
	"strconv"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

// nodeStatusScore maps Grid node availability to a numeric gauge value.
var nodeStatusScore = map[string]float64{
	"UP":       1,
	"DRAINING": 0.5,
	"DOWN":     0,
}

// sessionRecord tracks the lifecycle of a single session across scrapes.
type sessionRecord struct {
	caps      caps
	nodeID    string
	startUnix float64 // parsed from Grid's startTime field
	stopUnix  float64 // set when session disappears from the Grid response; 0 = still active
	stoppedAt time.Time
}

// nodeRecord tracks the current status and when the node entered it.
type nodeRecord struct {
	status string
	since  time.Time
}

type collector struct {
	client    *gridClient
	timeout   time.Duration
	gridTZ    *time.Location // timezone for parsing Grid's startTime strings
	retainFor time.Duration  // how long to keep stopped-session metrics after detection

	mu                 sync.Mutex
	sessions           map[string]*sessionRecord // keyed by session ID
	sessionsCompleted  float64                   // monotonically increasing; incremented when a session disappears

	nodeMu sync.Mutex
	nodes  map[string]*nodeRecord // keyed by node ID

	// Exporter health
	scrapeSuccess   *prometheus.Desc
	scrapeDuration  *prometheus.Desc

	// Grid-level
	gridInfo             *prometheus.Desc
	gridTotalSlots       *prometheus.Desc
	gridNodeCount        *prometheus.Desc
	gridMaxSessions      *prometheus.Desc
	gridSessionCount     *prometheus.Desc
	gridSessionQueueSize *prometheus.Desc

	// Node-level
	nodeStatus         *prometheus.Desc
	nodeStatusDuration *prometheus.Desc
	nodeMaxSessions    *prometheus.Desc
	nodeSlotCount      *prometheus.Desc
	nodeSessionCount   *prometheus.Desc

	// Stereotypes – slots available per (node, browser, version, platform)
	nodeStereotypeSlots *prometheus.Desc

	// Active sessions
	sessionDurationSeconds *prometheus.Desc
	sessionsActive         *prometheus.Desc

	// Session lifecycle
	sessionStartSeconds    *prometheus.Desc
	sessionStopSeconds     *prometheus.Desc
	sessionsCompletedTotal *prometheus.Desc

	// Queue
	sessionQueueRequests *prometheus.Desc
}

func newCollector(client *gridClient, timeout time.Duration, gridTZ *time.Location, retainFor time.Duration) *collector {
	node := []string{"node_id"}
	cap3 := []string{"browser_name", "browser_version", "platform_name"}
	sessionCap := []string{"session_id", "node_id", "browser_name", "browser_version", "platform_name", "test_name", "container_name"}

	return &collector{
		client:    client,
		timeout:   timeout,
		gridTZ:    gridTZ,
		retainFor: retainFor,
		sessions:  make(map[string]*sessionRecord),
		nodes:     make(map[string]*nodeRecord),

		scrapeSuccess: prometheus.NewDesc(
			"selenium_grid_scrape_success",
			"1 if the last scrape of the Grid GraphQL endpoint succeeded, 0 otherwise.",
			nil, nil),
		scrapeDuration: prometheus.NewDesc(
			"selenium_grid_scrape_duration_seconds",
			"Duration of the last Grid GraphQL scrape in seconds.",
			nil, nil),

		gridInfo: prometheus.NewDesc(
			"selenium_grid_info",
			"Selenium Grid version metadata. Value is always 1; use the version label.",
			[]string{"version"}, nil),
		gridTotalSlots: prometheus.NewDesc(
			"selenium_grid_total_slots",
			"Total number of slots across all nodes.",
			nil, nil),
		gridNodeCount: prometheus.NewDesc(
			"selenium_grid_node_count",
			"Number of registered nodes.",
			nil, nil),
		gridMaxSessions: prometheus.NewDesc(
			"selenium_grid_max_sessions",
			"Maximum concurrent sessions across all nodes.",
			nil, nil),
		gridSessionCount: prometheus.NewDesc(
			"selenium_grid_session_count",
			"Number of active sessions grid-wide.",
			nil, nil),
		gridSessionQueueSize: prometheus.NewDesc(
			"selenium_grid_session_queue_size",
			"Number of session requests waiting in the queue.",
			nil, nil),

		nodeStatus: prometheus.NewDesc(
			"selenium_grid_node_status",
			"Node availability: 1=UP, 0.5=DRAINING, 0=DOWN.",
			[]string{"node_id", "uri", "version", "os_name", "os_arch", "os_version"}, nil),
		nodeStatusDuration: prometheus.NewDesc(
			"selenium_grid_node_status_duration_seconds",
			"Seconds the node has continuously been in its current status (UP/DRAINING/DOWN).",
			[]string{"node_id", "status"}, nil),
		nodeMaxSessions: prometheus.NewDesc(
			"selenium_grid_node_max_sessions",
			"Maximum concurrent sessions for the node.",
			node, nil),
		nodeSlotCount: prometheus.NewDesc(
			"selenium_grid_node_slot_count",
			"Total slot count for the node.",
			node, nil),
		nodeSessionCount: prometheus.NewDesc(
			"selenium_grid_node_session_count",
			"Active session count for the node.",
			node, nil),

		nodeStereotypeSlots: prometheus.NewDesc(
			"selenium_grid_node_stereotype_slots_total",
			"Slots available per node stereotype (browser/version/platform combination).",
			append([]string{"node_id"}, cap3...), nil),

		sessionDurationSeconds: prometheus.NewDesc(
			"selenium_grid_session_duration_seconds",
			"Duration of an active session in seconds.",
			sessionCap, nil),
		sessionsActive: prometheus.NewDesc(
			"selenium_grid_sessions_active",
			"Number of active sessions by capability.",
			cap3, nil),

		sessionStartSeconds: prometheus.NewDesc(
			"selenium_grid_session_start_seconds",
			"Unix timestamp when the session started.",
			sessionCap, nil),
		sessionStopSeconds: prometheus.NewDesc(
			"selenium_grid_session_stop_seconds",
			"Unix timestamp when the session ended (detected on scrape after termination).",
			sessionCap, nil),
		sessionsCompletedTotal: prometheus.NewDesc(
			"selenium_grid_sessions_completed_total",
			"Total number of sessions that have ended since the exporter started.",
			nil, nil),

		sessionQueueRequests: prometheus.NewDesc(
			"selenium_grid_session_queue_requests",
			"Number of queued session requests by desired capability.",
			cap3, nil),
	}
}

func (c *collector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.scrapeSuccess
	ch <- c.scrapeDuration
	ch <- c.gridInfo
	ch <- c.gridTotalSlots
	ch <- c.gridNodeCount
	ch <- c.gridMaxSessions
	ch <- c.gridSessionCount
	ch <- c.gridSessionQueueSize
	ch <- c.nodeStatus
	ch <- c.nodeStatusDuration
	ch <- c.nodeMaxSessions
	ch <- c.nodeSlotCount
	ch <- c.nodeSessionCount
	ch <- c.nodeStereotypeSlots
	ch <- c.sessionDurationSeconds
	ch <- c.sessionsActive
	ch <- c.sessionStartSeconds
	ch <- c.sessionStopSeconds
	ch <- c.sessionsCompletedTotal
	ch <- c.sessionQueueRequests
}

func (c *collector) Collect(ch chan<- prometheus.Metric) {
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), c.timeout)
	defer cancel()

	data, err := c.client.query(ctx)
	duration := time.Since(start).Seconds()

	// Always emit scrape health so operators can alert on exporter/grid connectivity.
	success := 1.0
	if err != nil {
		success = 0.0
		log.Printf("selenium grid query failed: %v", err)
	}
	ch <- prometheus.MustNewConstMetric(c.scrapeSuccess, prometheus.GaugeValue, success)
	ch <- prometheus.MustNewConstMetric(c.scrapeDuration, prometheus.GaugeValue, duration)

	if err != nil {
		return
	}

	c.collectGrid(ch, &data.Grid)
	c.collectNodes(ch, data.NodesInfo.Nodes)
	c.collectSessions(ch, data.SessionsInfo.Sessions)
	c.collectQueue(ch, data.SessionsInfo.SessionQueueRequests)
}

func (c *collector) collectGrid(ch chan<- prometheus.Metric, g *gridSummary) {
	ch <- prometheus.MustNewConstMetric(c.gridInfo, prometheus.GaugeValue, 1, g.Version)

	gauge := func(d *prometheus.Desc, v int) {
		ch <- prometheus.MustNewConstMetric(d, prometheus.GaugeValue, float64(v))
	}
	gauge(c.gridTotalSlots, g.TotalSlots)
	gauge(c.gridNodeCount, g.NodeCount)
	gauge(c.gridMaxSessions, g.MaxSession)
	gauge(c.gridSessionCount, g.SessionCount)
	gauge(c.gridSessionQueueSize, g.SessionQueueSize)
}

func (c *collector) collectNodes(ch chan<- prometheus.Metric, nodes []nodeInfo) {
	now := time.Now()

	c.nodeMu.Lock()
	defer c.nodeMu.Unlock()

	// Update status records; reset the clock only when status actually changes.
	seen := make(map[string]struct{}, len(nodes))
	for _, n := range nodes {
		seen[n.ID] = struct{}{}
		if rec, exists := c.nodes[n.ID]; exists {
			if rec.status != n.Status {
				rec.status = n.Status
				rec.since = now
			}
		} else {
			c.nodes[n.ID] = &nodeRecord{status: n.Status, since: now}
		}
	}

	// Drop nodes that are no longer registered with the Grid.
	for id := range c.nodes {
		if _, present := seen[id]; !present {
			delete(c.nodes, id)
		}
	}

	// Emit per-node metrics.
	for _, n := range nodes {
		score := nodeStatusScore[n.Status]

		ch <- prometheus.MustNewConstMetric(c.nodeStatus, prometheus.GaugeValue, score,
			n.ID, n.URI, n.Version, n.OsInfo.Name, n.OsInfo.Arch, n.OsInfo.Version)
		ch <- prometheus.MustNewConstMetric(c.nodeMaxSessions, prometheus.GaugeValue, float64(n.MaxSession), n.ID)
		ch <- prometheus.MustNewConstMetric(c.nodeSlotCount, prometheus.GaugeValue, float64(n.SlotCount), n.ID)
		ch <- prometheus.MustNewConstMetric(c.nodeSessionCount, prometheus.GaugeValue, float64(n.SessionCount), n.ID)

		if rec, ok := c.nodes[n.ID]; ok {
			ch <- prometheus.MustNewConstMetric(c.nodeStatusDuration, prometheus.GaugeValue,
				now.Sub(rec.since).Seconds(), n.ID, rec.status)
		}

		for _, st := range parseStereotypes(n.Stereotypes) {
			ch <- prometheus.MustNewConstMetric(c.nodeStereotypeSlots, prometheus.GaugeValue, float64(st.Slots),
				n.ID, st.Stereotype.BrowserName, st.Stereotype.BrowserVersion, st.Stereotype.PlatformName)
		}
	}
}

func (c *collector) collectSessions(ch chan<- prometheus.Metric, sessions []sessionEntry) {
	now := time.Now()

	// Build index of currently active sessions from the Grid response.
	active := make(map[string]sessionEntry, len(sessions))
	for _, s := range sessions {
		active[s.ID] = s
	}

	c.mu.Lock()
	defer c.mu.Unlock()

	// Detect newly stopped sessions (present last scrape, absent now).
	for id, rec := range c.sessions {
		if _, stillActive := active[id]; !stillActive && rec.stopUnix == 0 {
			rec.stopUnix = float64(now.Unix())
			rec.stoppedAt = now
			c.sessionsCompleted++
		}
	}

	// Register new sessions and refresh records for active ones.
	for _, s := range sessions {
		cp := parseCaps(s.Capabilities)
		if rec, known := c.sessions[s.ID]; known {
			rec.caps = cp // capabilities can't change, but keep refresh cheap
		} else {
			c.sessions[s.ID] = &sessionRecord{
				caps:      cp,
				nodeID:    s.NodeID,
				startUnix: parseGridTime(s.StartTime, c.gridTZ),
			}
		}
	}

	// Prune stopped sessions beyond the retention window.
	for id, rec := range c.sessions {
		if rec.stopUnix != 0 && now.Sub(rec.stoppedAt) > c.retainFor {
			delete(c.sessions, id)
		}
	}

	completed := c.sessionsCompleted

	// Emit lifecycle metrics for all tracked sessions.
	for id, rec := range c.sessions {
		labels := []string{id, rec.nodeID, rec.caps.BrowserName, rec.caps.BrowserVersion, rec.caps.PlatformName, rec.caps.TestName, rec.caps.ContainerName}
		if rec.startUnix > 0 {
			ch <- prometheus.MustNewConstMetric(c.sessionStartSeconds, prometheus.GaugeValue, rec.startUnix, labels...)
		}
		if rec.stopUnix > 0 {
			ch <- prometheus.MustNewConstMetric(c.sessionStopSeconds, prometheus.GaugeValue, rec.stopUnix, labels...)
		}
	}

	// Emit duration and active-count metrics for currently active sessions.
	activeCounts := map[capTuple]float64{}
	for _, s := range sessions {
		cp := parseCaps(s.Capabilities)
		activeCounts[capTuple{cp.BrowserName, cp.BrowserVersion, cp.PlatformName}]++

		ms, _ := strconv.ParseFloat(s.SessionDurationMillis, 64)
		durationSec := ms / 1000
		// Fall back to wall-clock computation when Grid hasn't reported duration yet.
		if durationSec == 0 {
			if rec, ok := c.sessions[s.ID]; ok && rec.startUnix > 0 {
				durationSec = float64(now.Unix()) - rec.startUnix
			}
		}
		ch <- prometheus.MustNewConstMetric(c.sessionDurationSeconds, prometheus.GaugeValue, durationSec,
			s.ID, s.NodeID, cp.BrowserName, cp.BrowserVersion, cp.PlatformName, cp.TestName, cp.ContainerName)
	}
	for k, count := range activeCounts {
		ch <- prometheus.MustNewConstMetric(c.sessionsActive, prometheus.GaugeValue, count,
			k.browserName, k.browserVersion, k.platformName)
	}

	ch <- prometheus.MustNewConstMetric(c.sessionsCompletedTotal, prometheus.CounterValue, completed)
}

func (c *collector) collectQueue(ch chan<- prometheus.Metric, requests []string) {
	counts := map[capTuple]float64{}
	for _, raw := range requests {
		cp := parseCaps(raw)
		counts[capTuple{cp.BrowserName, cp.BrowserVersion, cp.PlatformName}]++
	}
	for k, count := range counts {
		ch <- prometheus.MustNewConstMetric(c.sessionQueueRequests, prometheus.GaugeValue, count,
			k.browserName, k.browserVersion, k.platformName)
	}
}

type capTuple struct {
	browserName    string
	browserVersion string
	platformName   string
}
