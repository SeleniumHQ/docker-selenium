package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"io"
	"log/slog"
	"math/big"
	"net"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
)

func discardLogger() *slog.Logger {
	return slog.New(slog.NewJSONHandler(io.Discard, nil))
}

// writeSelfSignedCert generates an ephemeral self-signed cert/key pair in dir
// and returns their paths, for exercising the TLS-enabled server path.
func writeSelfSignedCert(t *testing.T, dir string) (certPath, keyPath string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate key: %v", err)
	}
	tmpl := x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "localhost"},
		NotBefore:    time.Unix(0, 0),
		NotAfter:     time.Unix(1<<31-1, 0),
	}
	der, err := x509.CreateCertificate(rand.Reader, &tmpl, &tmpl, &key.PublicKey, key)
	if err != nil {
		t.Fatalf("create certificate: %v", err)
	}
	keyDER, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		t.Fatalf("marshal key: %v", err)
	}

	certPath = filepath.Join(dir, "cert.pem")
	keyPath = filepath.Join(dir, "key.pem")
	if err := os.WriteFile(certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}), 0o600); err != nil {
		t.Fatalf("write cert: %v", err)
	}
	if err := os.WriteFile(keyPath, pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: keyDER}), 0o600); err != nil {
		t.Fatalf("write key: %v", err)
	}
	return certPath, keyPath
}

func TestParseFlagsDefaults(t *testing.T) {
	for _, k := range []string{"LISTEN_ADDRESS", "SE_GRID_HTTP_TIMEOUT", "TLS_CERT_FILE", "TLS_KEY_FILE"} {
		t.Setenv(k, "")
	}
	cfg, err := parseFlags(nil)
	if err != nil {
		t.Fatalf("parseFlags: %v", err)
	}
	if cfg.listenAddr != ":8080" {
		t.Errorf("listenAddr = %q, want :8080", cfg.listenAddr)
	}
	if cfg.httpTimeout != 3*time.Second {
		t.Errorf("httpTimeout = %v, want 3s", cfg.httpTimeout)
	}
	if cfg.tlsCertFile != "" || cfg.tlsKeyFile != "" {
		t.Errorf("tls files = (%q,%q), want empty", cfg.tlsCertFile, cfg.tlsKeyFile)
	}
}

func TestParseFlagsOverridesAndEnv(t *testing.T) {
	t.Setenv("LISTEN_ADDRESS", ":9999")     // overridden by flag below
	t.Setenv("SE_GRID_HTTP_TIMEOUT", "500") // bare int → ms (env default)
	t.Setenv("TLS_CERT_FILE", "/etc/cert.pem")
	t.Setenv("TLS_KEY_FILE", "/etc/key.pem")

	cfg, err := parseFlags([]string{"-listen-address", ":7000"})
	if err != nil {
		t.Fatalf("parseFlags: %v", err)
	}
	if cfg.listenAddr != ":7000" {
		t.Errorf("listenAddr = %q, want flag value :7000", cfg.listenAddr)
	}
	if cfg.httpTimeout != 500*time.Millisecond {
		t.Errorf("httpTimeout = %v, want 500ms from bare-int env", cfg.httpTimeout)
	}
	if cfg.tlsCertFile != "/etc/cert.pem" || cfg.tlsKeyFile != "/etc/key.pem" {
		t.Errorf("tls files = (%q,%q), want env defaults", cfg.tlsCertFile, cfg.tlsKeyFile)
	}
}

func TestParseFlagsInvalid(t *testing.T) {
	if _, err := parseFlags([]string{"-unknown-flag"}); err == nil {
		t.Error("expected error for unknown flag, got nil")
	}
}

func TestEnvOr(t *testing.T) {
	t.Setenv("SOME_KEY", "value")
	if got := envOr("SOME_KEY", "fallback"); got != "value" {
		t.Errorf("envOr(set) = %q, want value", got)
	}
	t.Setenv("SOME_KEY", "")
	if got := envOr("SOME_KEY", "fallback"); got != "fallback" {
		t.Errorf("envOr(empty) = %q, want fallback", got)
	}
}

func TestEnvDurationOr(t *testing.T) {
	tests := []struct {
		name string
		val  string
		want time.Duration
	}{
		{"unset returns fallback", "", 2 * time.Second},
		{"duration string", "1500ms", 1500 * time.Millisecond},
		{"bare integer is milliseconds", "250", 250 * time.Millisecond},
		{"garbage returns fallback", "not-a-duration", 2 * time.Second},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("DUR_KEY", tt.val)
			if got := envDurationOr("DUR_KEY", 2*time.Second); got != tt.want {
				t.Errorf("envDurationOr(%q) = %v, want %v", tt.val, got, tt.want)
			}
		})
	}
}

func TestCollectGridEnv(t *testing.T) {
	// Clear all keys, then set a subset; only the set keys must appear.
	for _, k := range gridEnvKeys {
		t.Setenv(k, "")
	}
	t.Setenv("SE_GRID_URL", "http://grid:4444/graphql")
	t.Setenv("SE_USERNAME", "admin")

	env := collectGridEnv()
	if env["SE_GRID_URL"] != "http://grid:4444/graphql" {
		t.Errorf("SE_GRID_URL = %q, unexpected", env["SE_GRID_URL"])
	}
	if env["SE_USERNAME"] != "admin" {
		t.Errorf("SE_USERNAME = %q, unexpected", env["SE_USERNAME"])
	}
	if _, ok := env["SE_PASSWORD"]; ok {
		t.Error("unset SE_PASSWORD should be absent from the map")
	}
}

func TestRealMainHelp(t *testing.T) {
	if code := realMain(context.Background(), []string{"-h"}, discardLogger()); code != 0 {
		t.Errorf("realMain(-h) = %d, want 0", code)
	}
}

func TestRealMainInvalidFlags(t *testing.T) {
	if code := realMain(context.Background(), []string{"-nope"}, discardLogger()); code != 2 {
		t.Errorf("realMain(bad flag) = %d, want 2", code)
	}
}

func TestRealMainRunError(t *testing.T) {
	// Valid flags but an unbindable listen address: run fails, realMain → 1.
	code := realMain(context.Background(), []string{"-listen-address", "256.256.256.256:99999"}, discardLogger())
	if code != 1 {
		t.Errorf("realMain(listen error) = %d, want 1", code)
	}
}

func TestRealMainGracefulShutdown(t *testing.T) {
	// Valid flags on an ephemeral port; cancelling the context drains the server
	// and realMain returns success (0).
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan int, 1)
	go func() {
		done <- realMain(ctx, []string{"-listen-address", "127.0.0.1:0"}, discardLogger())
	}()

	time.Sleep(100 * time.Millisecond)
	cancel()

	select {
	case code := <-done:
		if code != 0 {
			t.Errorf("realMain graceful shutdown = %d, want 0", code)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("realMain did not return after context cancellation")
	}
}

func TestRunListenError(t *testing.T) {
	// An unbindable address makes net.Listen fail, exercising run's error return
	// after the server has been fully assembled.
	cfg := config{listenAddr: "256.256.256.256:99999", httpTimeout: time.Second}
	if err := run(context.Background(), cfg, discardLogger()); err == nil {
		t.Error("expected listen error, got nil")
	}
}

func TestRunTLSError(t *testing.T) {
	// Non-existent cert/key files make the TLS credential setup fail.
	cfg := config{
		listenAddr:  "127.0.0.1:0",
		httpTimeout: time.Second,
		tlsCertFile: filepath.Join(t.TempDir(), "missing-cert.pem"),
		tlsKeyFile:  filepath.Join(t.TempDir(), "missing-key.pem"),
	}
	if err := run(context.Background(), cfg, discardLogger()); err == nil {
		t.Error("expected TLS credential error, got nil")
	}
}

func TestRunTLSGracefulShutdown(t *testing.T) {
	// Valid cert/key enables TLS; cancelling the context drains cleanly. Covers
	// the TLS-credential branch of run.
	certPath, keyPath := writeSelfSignedCert(t, t.TempDir())
	cfg := config{listenAddr: "127.0.0.1:0", httpTimeout: time.Second, tlsCertFile: certPath, tlsKeyFile: keyPath}
	ctx, cancel := context.WithCancel(context.Background())

	done := make(chan error, 1)
	go func() { done <- run(ctx, cfg, discardLogger()) }()

	time.Sleep(100 * time.Millisecond)
	cancel()

	select {
	case err := <-done:
		if err != nil {
			t.Errorf("run (TLS) graceful shutdown returned %v, want nil", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("run (TLS) did not return after context cancellation")
	}
}

func TestServeServerStopped(t *testing.T) {
	// srv.Stop() makes Serve return grpc.ErrServerStopped, which serve treats as
	// a clean exit (nil).
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	srv := grpc.NewServer()
	hs := health.NewServer()

	done := make(chan error, 1)
	go func() { done <- serve(context.Background(), srv, hs, lis, discardLogger()) }()

	time.Sleep(100 * time.Millisecond)
	srv.Stop()

	select {
	case err := <-done:
		if err != nil {
			t.Errorf("serve after Stop = %v, want nil", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("serve did not return after Stop")
	}
}

func TestServeListenerError(t *testing.T) {
	// A closed listener makes Serve fail with a non-ErrServerStopped error, which
	// serve must surface.
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	lis.Close()

	srv := grpc.NewServer()
	defer srv.Stop()
	hs := health.NewServer()

	if err := serve(context.Background(), srv, hs, lis, discardLogger()); err == nil {
		t.Error("expected serve error on closed listener, got nil")
	}
}

func TestRunGracefulShutdown(t *testing.T) {
	// Bind an ephemeral port and cancel the context: run must serve and then
	// drain cleanly, returning nil.
	cfg := config{listenAddr: "127.0.0.1:0", httpTimeout: time.Second}
	ctx, cancel := context.WithCancel(context.Background())

	done := make(chan error, 1)
	go func() { done <- run(ctx, cfg, discardLogger()) }()

	// Give the server a moment to start serving, then request shutdown.
	time.Sleep(100 * time.Millisecond)
	cancel()

	select {
	case err := <-done:
		if err != nil {
			t.Errorf("run graceful shutdown returned %v, want nil", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("run did not return after context cancellation")
	}
}
