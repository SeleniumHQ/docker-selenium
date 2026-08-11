package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestParseGridTime(t *testing.T) {
	hcm, err := time.LoadLocation("Asia/Ho_Chi_Minh")
	if err != nil {
		t.Fatalf("load location: %v", err)
	}

	tests := []struct {
		name string
		in   string
		loc  *time.Location
		want float64
	}{
		{
			name: "valid UTC",
			in:   "02/01/2006 15:04:05",
			loc:  time.UTC,
			want: float64(time.Date(2006, 1, 2, 15, 4, 5, 0, time.UTC).Unix()),
		},
		{
			name: "valid non-UTC honours location",
			in:   "02/01/2006 15:04:05",
			loc:  hcm,
			want: float64(time.Date(2006, 1, 2, 15, 4, 5, 0, hcm).Unix()),
		},
		{
			name: "nil location defaults to UTC",
			in:   "02/01/2006 15:04:05",
			loc:  nil,
			want: float64(time.Date(2006, 1, 2, 15, 4, 5, 0, time.UTC).Unix()),
		},
		{
			name: "empty string returns zero",
			in:   "",
			loc:  time.UTC,
			want: 0,
		},
		{
			name: "unparseable string returns zero",
			in:   "2006-01-02T15:04:05Z", // wrong layout (RFC3339, not Grid's dd/MM/yyyy)
			loc:  time.UTC,
			want: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseGridTime(tt.in, tt.loc); got != tt.want {
				t.Errorf("parseGridTime(%q) = %v, want %v", tt.in, got, tt.want)
			}
		})
	}
}

func TestParseCaps(t *testing.T) {
	tests := []struct {
		name string
		raw  string
		want caps
	}{
		{
			name: "full capabilities incl se: prefixed",
			raw:  `{"browserName":"chrome","browserVersion":"124","platformName":"linux","se:name":"login-test","se:containerName":"node-chrome-1"}`,
			want: caps{BrowserName: "chrome", BrowserVersion: "124", PlatformName: "linux", TestName: "login-test", ContainerName: "node-chrome-1"},
		},
		{
			name: "partial capabilities leave the rest empty",
			raw:  `{"browserName":"firefox"}`,
			want: caps{BrowserName: "firefox"},
		},
		{
			name: "empty string yields zero caps without panic",
			raw:  "",
			want: caps{},
		},
		{
			name: "malformed json yields zero caps without panic",
			raw:  `{"browserName":`,
			want: caps{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := parseCaps(tt.raw); got != tt.want {
				t.Errorf("parseCaps(%q) = %+v, want %+v", tt.raw, got, tt.want)
			}
		})
	}
}

func TestParseStereotypes(t *testing.T) {
	t.Run("valid stereotype array", func(t *testing.T) {
		raw := `[{"stereotype":{"browserName":"chrome","browserVersion":"124","platformName":"linux"},"slots":4},` +
			`{"stereotype":{"browserName":"firefox","browserVersion":"125","platformName":"linux"},"slots":2}]`
		got := parseStereotypes(raw)
		if len(got) != 2 {
			t.Fatalf("expected 2 entries, got %d", len(got))
		}
		if got[0].Slots != 4 || got[0].Stereotype.BrowserName != "chrome" {
			t.Errorf("entry[0] = %+v, unexpected", got[0])
		}
		if got[1].Slots != 2 || got[1].Stereotype.BrowserName != "firefox" {
			t.Errorf("entry[1] = %+v, unexpected", got[1])
		}
	})

	t.Run("malformed json yields nil without panic", func(t *testing.T) {
		if got := parseStereotypes(`[{"stereotype":`); len(got) != 0 {
			t.Errorf("expected empty slice, got %+v", got)
		}
	})

	t.Run("empty string yields nil without panic", func(t *testing.T) {
		if got := parseStereotypes(""); len(got) != 0 {
			t.Errorf("expected empty slice, got %+v", got)
		}
	})
}

// okResponseBody builds a minimal valid GraphQL data envelope for the client tests.
func okResponseBody(t *testing.T) string {
	t.Helper()
	resp := gqlResponse{Data: &gridData{
		Grid: gridSummary{Version: "4.47.0", NodeCount: 1, TotalSlots: 4},
	}}
	b, err := json.Marshal(resp)
	if err != nil {
		t.Fatalf("marshal response: %v", err)
	}
	return string(b)
}

func TestGridClientQuerySuccess(t *testing.T) {
	var gotBody string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			t.Errorf("method = %s, want POST", r.Method)
		}
		if ct := r.Header.Get("Content-Type"); ct != "application/json" {
			t.Errorf("Content-Type = %q, want application/json", ct)
		}
		raw, _ := io.ReadAll(r.Body)
		gotBody = string(raw)
		_, _ = io.WriteString(w, okResponseBody(t))
	}))
	defer srv.Close()

	client := newGridClient(srv.URL, "", "", 5*time.Second)
	data, err := client.query(context.Background())
	if err != nil {
		t.Fatalf("query: %v", err)
	}
	if data.Grid.Version != "4.47.0" || data.Grid.NodeCount != 1 {
		t.Errorf("decoded grid = %+v, unexpected", data.Grid)
	}
	// The request body must carry the GraphQL query so a server-side schema
	// change (or a marshaling regression) is caught.
	var sent gqlRequest
	if err := json.Unmarshal([]byte(gotBody), &sent); err != nil {
		t.Fatalf("request body not valid JSON: %v (%s)", err, gotBody)
	}
	if !strings.Contains(sent.Query, "nodesInfo") || !strings.Contains(sent.Query, "sessionsInfo") {
		t.Errorf("request query missing expected fields: %s", sent.Query)
	}
}

func TestGridClientQueryBasicAuth(t *testing.T) {
	t.Run("credentials set send Authorization header", func(t *testing.T) {
		srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user, pass, ok := r.BasicAuth()
			if !ok || user != "admin" || pass != "secret" {
				t.Errorf("basic auth = (%q,%q,%v), want (admin,secret,true)", user, pass, ok)
			}
			_, _ = io.WriteString(w, okResponseBody(t))
		}))
		defer srv.Close()

		client := newGridClient(srv.URL, "admin", "secret", 5*time.Second)
		if _, err := client.query(context.Background()); err != nil {
			t.Fatalf("query: %v", err)
		}
	})

	t.Run("no credentials omit Authorization header", func(t *testing.T) {
		srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if _, _, ok := r.BasicAuth(); ok {
				t.Error("Authorization header set despite empty credentials")
			}
			_, _ = io.WriteString(w, okResponseBody(t))
		}))
		defer srv.Close()

		client := newGridClient(srv.URL, "", "", 5*time.Second)
		if _, err := client.query(context.Background()); err != nil {
			t.Fatalf("query: %v", err)
		}
	})
}

func TestGridClientQueryErrors(t *testing.T) {
	tests := []struct {
		name    string
		body    string
		wantErr string
	}{
		{
			name:    "graphql errors array surfaces first message",
			body:    `{"errors":[{"message":"unauthorized"}]}`,
			wantErr: "unauthorized",
		},
		{
			name:    "null data is an error",
			body:    `{"data":null}`,
			wantErr: "empty data",
		},
		{
			name:    "malformed json body is a decode error",
			body:    `{not-json`,
			wantErr: "decode response",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				_, _ = io.WriteString(w, tt.body)
			}))
			defer srv.Close()

			client := newGridClient(srv.URL, "", "", 5*time.Second)
			_, err := client.query(context.Background())
			if err == nil {
				t.Fatal("expected error, got nil")
			}
			if !strings.Contains(err.Error(), tt.wantErr) {
				t.Errorf("error = %q, want it to contain %q", err.Error(), tt.wantErr)
			}
		})
	}
}

func TestGridClientQueryContextCancelled(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-r.Context().Done() // never respond; wait for the client to give up
	}))
	defer srv.Close()

	ctx, cancel := context.WithCancel(context.Background())
	cancel() // already cancelled before the call

	client := newGridClient(srv.URL, "", "", 5*time.Second)
	if _, err := client.query(ctx); err == nil {
		t.Fatal("expected error from cancelled context, got nil")
	}
}
