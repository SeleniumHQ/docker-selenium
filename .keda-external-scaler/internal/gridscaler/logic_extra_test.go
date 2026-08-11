package gridscaler

import (
	"testing"

	"github.com/go-logr/logr"
)

func Test_parseCapabilitiesToMap(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantLen int
		wantErr bool
	}{
		{"empty string yields empty map", "", 0, false},
		{"valid json object is parsed", `{"myApp:version": "beta"}`, 1, false},
		{"invalid json returns error", `{not valid`, 0, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseCapabilitiesToMap(tt.input)
			if (err != nil) != tt.wantErr {
				t.Fatalf("parseCapabilitiesToMap() error = %v, wantErr %v", err, tt.wantErr)
			}
			if tt.wantErr {
				return
			}
			if len(got) != tt.wantLen {
				t.Errorf("len = %d, want %d", len(got), tt.wantLen)
			}
		})
	}
}

func Test_countMatchingSessions(t *testing.T) {
	t.Run("counts sessions whose stereotype matches", func(t *testing.T) {
		sessions := Sessions{
			{Slot: Slot{Stereotype: `{"browserName": "chrome", "platformName": "linux"}`}},
			{Slot: Slot{Stereotype: `{"browserName": "firefox", "platformName": "linux"}`}},
		}
		got := countMatchingSessions(sessions, "chrome", "", "chrome", "linux", map[string]interface{}{}, logr.Discard())
		if got != 1 {
			t.Errorf("countMatchingSessions() = %d, want 1", got)
		}
	})

	t.Run("skips sessions with unparseable stereotype json", func(t *testing.T) {
		sessions := Sessions{
			{Slot: Slot{Stereotype: `not-json`}},
			{Slot: Slot{Stereotype: `{"browserName": "chrome"}`}},
		}
		got := countMatchingSessions(sessions, "chrome", "", "chrome", "", map[string]interface{}{}, logr.Discard())
		if got != 1 {
			t.Errorf("countMatchingSessions() = %d, want 1 (bad-json session ignored)", got)
		}
	})
}

// Test_getCountFromSeleniumResponse_malformed covers the resilience branches of
// getCountFromSeleniumResponse: malformed trigger capabilities, malformed queued
// request capabilities, and malformed node stereotypes must be logged and
// skipped rather than aborting the count.
func Test_getCountFromSeleniumResponse_malformed(t *testing.T) {
	t.Run("invalid trigger capabilities are tolerated", func(t *testing.T) {
		body := []byte(`{"data":{"grid":{},"nodesInfo":{"nodes":[]},"sessionsInfo":{"sessionQueueRequests":[]}}}`)
		// enableManagedDownloads=false so the nil map from the parse error is not written to.
		newNodes, onGoing, err := getCountFromSeleniumResponse(body, "chrome", "", "chrome", "linux", 1, false, `{not valid`, logr.Discard())
		if err != nil {
			t.Fatalf("getCountFromSeleniumResponse() error = %v", err)
		}
		if newNodes != 0 || onGoing != 0 {
			t.Errorf("got (%d,%d), want (0,0)", newNodes, onGoing)
		}
	})

	t.Run("invalid queued request capabilities are skipped", func(t *testing.T) {
		body := []byte(`{"data":{"grid":{},"nodesInfo":{"nodes":[]},"sessionsInfo":{"sessionQueueRequests":["not-json"]}}}`)
		newNodes, onGoing, err := getCountFromSeleniumResponse(body, "chrome", "", "chrome", "linux", 1, true, "", logr.Discard())
		if err != nil {
			t.Fatalf("getCountFromSeleniumResponse() error = %v", err)
		}
		if newNodes != 0 || onGoing != 0 {
			t.Errorf("got (%d,%d), want (0,0)", newNodes, onGoing)
		}
	})

	t.Run("matched request against a node with invalid stereotypes still scales up", func(t *testing.T) {
		body := []byte(`{
			"data": {
				"grid": { "sessionCount": 0, "maxSession": 1, "totalSlots": 1 },
				"nodesInfo": {
					"nodes": [
						{
							"id": "node-1",
							"status": "UP",
							"sessionCount": 0,
							"maxSession": 1,
							"slotCount": 1,
							"stereotypes": "not-json",
							"sessions": []
						}
					]
				},
				"sessionsInfo": {
					"sessionQueueRequests": [
						"{\"browserName\": \"chrome\", \"platformName\": \"linux\"}"
					]
				}
			}
		}`)
		newNodes, onGoing, err := getCountFromSeleniumResponse(body, "chrome", "", "chrome", "linux", 1, true, "", logr.Discard())
		if err != nil {
			t.Fatalf("getCountFromSeleniumResponse() error = %v", err)
		}
		// The node's slots cannot be matched (unparseable stereotypes), so a new
		// Node must be scaled up for the queued request.
		if newNodes != 1 || onGoing != 0 {
			t.Errorf("got (%d,%d), want (1,0)", newNodes, onGoing)
		}
	})
}
