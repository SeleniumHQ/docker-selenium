package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// gridDateFormat is the layout used by Selenium Grid's DateTimeFormatter:
// DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss").withZone(ZoneId.systemDefault())
const gridDateFormat = "02/01/2006 15:04:05"

// parseGridTime parses a Grid-formatted startTime string into a Unix timestamp.
// loc should match the Grid server's JVM timezone; defaults to UTC when nil.
func parseGridTime(s string, loc *time.Location) float64 {
	if loc == nil {
		loc = time.UTC
	}
	t, err := time.ParseInLocation(gridDateFormat, s, loc)
	if err != nil {
		return 0
	}
	return float64(t.Unix())
}

// gridQuery fetches everything needed to produce all metrics in one round-trip.
const gridQuery = `{
  grid {
    uri
    totalSlots
    nodeCount
    maxSession
    sessionCount
    sessionQueueSize
    version
  }
  nodesInfo {
    nodes {
      id
      uri
      status
      maxSession
      slotCount
      sessionCount
      stereotypes
      version
      osInfo {
        arch
        name
        version
      }
    }
  }
  sessionsInfo {
    sessionQueueRequests
    sessions {
      id
      capabilities
      startTime
      sessionDurationMillis
      nodeId
      nodeUri
    }
  }
}`

// ── GraphQL wire types ────────────────────────────────────────────────────────

type gqlRequest struct {
	Query string `json:"query"`
}

type gqlResponse struct {
	Data   *gridData  `json:"data"`
	Errors []gqlError `json:"errors"`
}

type gqlError struct {
	Message string `json:"message"`
}

type gridData struct {
	Grid         gridSummary  `json:"grid"`
	NodesInfo    nodesInfo    `json:"nodesInfo"`
	SessionsInfo sessionsInfo `json:"sessionsInfo"`
}

type gridSummary struct {
	URI              string `json:"uri"`
	TotalSlots       int    `json:"totalSlots"`
	NodeCount        int    `json:"nodeCount"`
	MaxSession       int    `json:"maxSession"`
	SessionCount     int    `json:"sessionCount"`
	SessionQueueSize int    `json:"sessionQueueSize"`
	Version          string `json:"version"`
}

type nodesInfo struct {
	Nodes []nodeInfo `json:"nodes"`
}

type nodeInfo struct {
	ID           string `json:"id"`
	URI          string `json:"uri"`
	Status       string `json:"status"`
	MaxSession   int    `json:"maxSession"`
	SlotCount    int    `json:"slotCount"`
	SessionCount int    `json:"sessionCount"`
	Stereotypes  string `json:"stereotypes"` // JSON-encoded []stereotypeEntry
	Version      string `json:"version"`
	OsInfo       osInfo `json:"osInfo"`
}

type osInfo struct {
	Arch    string `json:"arch"`
	Name    string `json:"name"`
	Version string `json:"version"`
}

type sessionsInfo struct {
	SessionQueueRequests []string       `json:"sessionQueueRequests"` // JSON-encoded capabilities
	Sessions             []sessionEntry `json:"sessions"`
}

type sessionEntry struct {
	ID                    string `json:"id"`
	Capabilities          string `json:"capabilities"` // JSON-encoded
	StartTime             string `json:"startTime"`     // "dd/MM/yyyy HH:mm:ss"
	SessionDurationMillis string `json:"sessionDurationMillis"`
	NodeID                string `json:"nodeId"`
	NodeURI               string `json:"nodeUri"`
}

// ── Capability / stereotype parsing ──────────────────────────────────────────

// caps holds the capability fields we expose as metric labels.
type caps struct {
	BrowserName   string `json:"browserName"`
	BrowserVersion string `json:"browserVersion"`
	PlatformName  string `json:"platformName"`
	TestName      string `json:"se:name"`
	ContainerName string `json:"se:containerName"`
}

type stereotypeEntry struct {
	Stereotype caps `json:"stereotype"`
	Slots      int  `json:"slots"`
}

func parseCaps(raw string) caps {
	var c caps
	_ = json.Unmarshal([]byte(raw), &c)
	return c
}

func parseStereotypes(raw string) []stereotypeEntry {
	var entries []stereotypeEntry
	_ = json.Unmarshal([]byte(raw), &entries)
	return entries
}

// ── HTTP client ───────────────────────────────────────────────────────────────

type gridClient struct {
	http     *http.Client
	endpoint string
	username string
	password string
}

func newGridClient(endpoint, username, password string, timeout time.Duration) *gridClient {
	return &gridClient{
		http:     &http.Client{Timeout: timeout},
		endpoint: endpoint,
		username: username,
		password: password,
	}
}

func (gc *gridClient) query(ctx context.Context) (*gridData, error) {
	body, err := json.Marshal(gqlRequest{Query: gridQuery})
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, gc.endpoint, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	if gc.username != "" && gc.password != "" {
		req.SetBasicAuth(gc.username, gc.password)
	}

	resp, err := gc.http.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var gqlResp gqlResponse
	if err := json.NewDecoder(resp.Body).Decode(&gqlResp); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}
	if len(gqlResp.Errors) > 0 {
		return nil, fmt.Errorf("graphql: %s", gqlResp.Errors[0].Message)
	}
	if gqlResp.Data == nil {
		return nil, fmt.Errorf("graphql: empty data")
	}
	return gqlResp.Data, nil
}
