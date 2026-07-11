package gridscaler

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"
)

// gridQuery is the GraphQL query sent to the Selenium Grid. It is kept
// byte-identical to the built-in KEDA scaler's query so the response shape and
// downstream parsing remain in lockstep.
const gridQuery = "{ grid { sessionCount, maxSession, totalSlots }, nodesInfo { nodes { id, status, sessionCount, maxSession, slotCount, stereotypes, sessions { id, capabilities, slot { id, stereotype } } } }, sessionsInfo { sessionQueueRequests } }"

// GridClient issues the Grid GraphQL query. It caches one *http.Client per
// unsafeSsl setting so repeated polls reuse connections rather than performing a
// fresh TLS handshake each time.
type GridClient struct {
	timeout time.Duration

	mu      sync.Mutex
	clients map[bool]*http.Client
}

// NewGridClient returns a GridClient using the given per-request timeout.
func NewGridClient(timeout time.Duration) *GridClient {
	return &GridClient{
		timeout: timeout,
		clients: make(map[bool]*http.Client),
	}
}

func (c *GridClient) httpClient(unsafeSsl bool) *http.Client {
	c.mu.Lock()
	defer c.mu.Unlock()
	if client, ok := c.clients[unsafeSsl]; ok {
		return client
	}
	client := newHTTPClient(c.timeout, unsafeSsl)
	c.clients[unsafeSsl] = client
	return client
}

// newHTTPClient mirrors kedautil.CreateHTTPClient: a client honouring proxies
// from the environment, with optional TLS verification skip.
func newHTTPClient(timeout time.Duration, unsafeSsl bool) *http.Client {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		TLSClientConfig: &tls.Config{
			MinVersion:         tls.VersionTLS12,
			InsecureSkipVerify: unsafeSsl, //nolint:gosec // opt-in via unsafeSsl trigger metadata
		},
	}
	return &http.Client{
		Timeout:   timeout,
		Transport: transport,
	}
}

// Query POSTs the Grid GraphQL query using the auth configured in meta and
// returns the raw response body. A non-200 status is returned as an error.
func (c *GridClient) Query(ctx context.Context, meta *Metadata) ([]byte, error) {
	body, err := json.Marshal(map[string]string{"query": gridQuery})
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, meta.URL, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	if (meta.AuthType == "" || strings.EqualFold(meta.AuthType, "Basic")) && meta.Username != "" && meta.Password != "" {
		req.SetBasicAuth(meta.Username, meta.Password)
	} else if !strings.EqualFold(meta.AuthType, "Basic") && meta.AccessToken != "" {
		req.Header.Set("Authorization", fmt.Sprintf("%s %s", meta.AuthType, meta.AccessToken))
	}

	res, err := c.httpClient(meta.UnsafeSsl).Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("selenium grid returned response status code: %d", res.StatusCode)
	}

	b, err := io.ReadAll(res.Body)
	if err != nil {
		return nil, fmt.Errorf("reading selenium grid response body: %w", err)
	}
	return b, nil
}
