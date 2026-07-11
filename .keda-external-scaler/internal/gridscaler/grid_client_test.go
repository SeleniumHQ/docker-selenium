package gridscaler

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestGridClient_Query(t *testing.T) {
	t.Run("sends the GraphQL query and returns the body", func(t *testing.T) {
		var gotBody map[string]string
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method != http.MethodPost {
				t.Errorf("method = %s, want POST", r.Method)
			}
			_ = json.NewDecoder(r.Body).Decode(&gotBody)
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"data":{}}`))
		}))
		defer server.Close()

		c := NewGridClient(3 * time.Second)
		b, err := c.Query(context.Background(), &Metadata{URL: server.URL})
		if err != nil {
			t.Fatalf("Query() error = %v", err)
		}
		if string(b) != `{"data":{}}` {
			t.Errorf("body = %s", b)
		}
		if gotBody["query"] != gridQuery {
			t.Errorf("query = %q, want %q", gotBody["query"], gridQuery)
		}
	})

	t.Run("sets Basic auth when username and password are present", func(t *testing.T) {
		var user, pass string
		var okBasic bool
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			user, pass, okBasic = r.BasicAuth()
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{}`))
		}))
		defer server.Close()

		c := NewGridClient(3 * time.Second)
		_, err := c.Query(context.Background(), &Metadata{URL: server.URL, Username: "u", Password: "p"})
		if err != nil {
			t.Fatalf("Query() error = %v", err)
		}
		if !okBasic || user != "u" || pass != "p" {
			t.Errorf("basic auth = (%q,%q,%v), want (u,p,true)", user, pass, okBasic)
		}
	})

	t.Run("sets bearer-style Authorization header for non-Basic authType", func(t *testing.T) {
		var auth string
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			auth = r.Header.Get("Authorization")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{}`))
		}))
		defer server.Close()

		c := NewGridClient(3 * time.Second)
		_, err := c.Query(context.Background(), &Metadata{URL: server.URL, AuthType: "OAuth2", AccessToken: "tok"})
		if err != nil {
			t.Fatalf("Query() error = %v", err)
		}
		if auth != "OAuth2 tok" {
			t.Errorf("Authorization = %q, want %q", auth, "OAuth2 tok")
		}
	})

	t.Run("non-200 status returns an error", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusInternalServerError)
		}))
		defer server.Close()

		c := NewGridClient(3 * time.Second)
		if _, err := c.Query(context.Background(), &Metadata{URL: server.URL}); err == nil {
			t.Error("Query() error = nil, want non-nil for 500 response")
		}
	})

	t.Run("caches one client per unsafeSsl value", func(t *testing.T) {
		c := NewGridClient(3 * time.Second)
		a1 := c.httpClient(false)
		a2 := c.httpClient(false)
		b1 := c.httpClient(true)
		if a1 != a2 {
			t.Error("expected cached client reuse for unsafeSsl=false")
		}
		if a1 == b1 {
			t.Error("expected distinct clients for different unsafeSsl values")
		}
	})
}
