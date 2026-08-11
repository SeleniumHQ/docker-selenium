package gridscaler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

// TestGridClient_Query_InvalidURL covers the request-construction error path:
// a URL containing a control character makes http.NewRequestWithContext fail
// before any network call.
func TestGridClient_Query_InvalidURL(t *testing.T) {
	c := NewGridClient(3 * time.Second)
	if _, err := c.Query(context.Background(), &Metadata{URL: "http://\x7f/graphql"}); err == nil {
		t.Error("Query() error = nil, want non-nil for malformed URL")
	}
}

// TestGridClient_Query_ShortBody covers the response-read error path: the server
// promises more bytes via Content-Length than it delivers, then closes, so
// io.ReadAll returns an unexpected-EOF error.
func TestGridClient_Query_ShortBody(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		hj, ok := w.(http.Hijacker)
		if !ok {
			t.Fatal("ResponseWriter does not support hijacking")
		}
		conn, buf, err := hj.Hijack()
		if err != nil {
			t.Errorf("hijack error = %v", err)
			return
		}
		// Content-Length claims 100 bytes but only 5 are written before close.
		_, _ = buf.WriteString("HTTP/1.1 200 OK\r\nContent-Length: 100\r\n\r\nshort")
		_ = buf.Flush()
		_ = conn.Close()
	}))
	defer server.Close()

	c := NewGridClient(3 * time.Second)
	if _, err := c.Query(context.Background(), &Metadata{URL: server.URL}); err == nil {
		t.Error("Query() error = nil, want non-nil for truncated response body")
	}
}
