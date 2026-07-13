// Command selenium-grid-scaler is a KEDA external scaler for Selenium Grid.
//
// It serves KEDA's externalscaler.ExternalScaler gRPC service, translating the
// Grid's GraphQL state into the number of Nodes KEDA should scale to. It is a
// standalone extraction of KEDA's built-in selenium-grid scaler so scaling
// behaviour can be released on the docker-selenium cadence.
package main

import (
	"context"
	"errors"
	"flag"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/go-logr/logr"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"

	pb "github.com/SeleniumHQ/docker-selenium/keda-external-scaler/externalscaler"
	"github.com/SeleniumHQ/docker-selenium/keda-external-scaler/internal/gridscaler"
)

// gridEnvKeys are the environment variables read as server-side fallbacks for
// Grid URL and credentials (used when trigger metadata omits them, since KEDA
// does not forward TriggerAuthentication authParams to external scalers).
var gridEnvKeys = []string{"SE_GRID_URL", "SE_GRID_AUTH_TYPE", "SE_USERNAME", "SE_PASSWORD", "SE_ACCESS_TOKEN"}

type config struct {
	listenAddr  string
	httpTimeout time.Duration
	tlsCertFile string
	tlsKeyFile  string
}

func parseFlags(args []string) (config, error) {
	fs := flag.NewFlagSet("selenium-grid-scaler", flag.ContinueOnError)
	var cfg config
	fs.StringVar(&cfg.listenAddr, "listen-address", envOr("LISTEN_ADDRESS", ":8080"), "gRPC listen address (env LISTEN_ADDRESS)")
	fs.DurationVar(&cfg.httpTimeout, "grid-http-timeout", envDurationOr("SE_GRID_HTTP_TIMEOUT", 3*time.Second), "per-request timeout for Grid GraphQL queries (env SE_GRID_HTTP_TIMEOUT)")
	fs.StringVar(&cfg.tlsCertFile, "tls-cert-file", os.Getenv("TLS_CERT_FILE"), "path to server TLS certificate; enables TLS when set with --tls-key-file (env TLS_CERT_FILE)")
	fs.StringVar(&cfg.tlsKeyFile, "tls-key-file", os.Getenv("TLS_KEY_FILE"), "path to server TLS private key (env TLS_KEY_FILE)")
	if err := fs.Parse(args); err != nil {
		return config{}, err
	}
	return cfg, nil
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))

	cfg, err := parseFlags(os.Args[1:])
	if err != nil {
		// flag already printed usage/error for -h and parse failures.
		if errors.Is(err, flag.ErrHelp) {
			return
		}
		logger.Error("invalid flags", "err", err)
		os.Exit(2)
	}

	if err := run(cfg, logger); err != nil {
		logger.Error("server exited with error", "err", err)
		os.Exit(1)
	}
}

func run(cfg config, logger *slog.Logger) error {
	env := collectGridEnv()

	var opts []grpc.ServerOption
	if cfg.tlsCertFile != "" && cfg.tlsKeyFile != "" {
		creds, err := credentials.NewServerTLSFromFile(cfg.tlsCertFile, cfg.tlsKeyFile)
		if err != nil {
			return err
		}
		opts = append(opts, grpc.Creds(creds))
		logger.Info("TLS enabled", "certFile", cfg.tlsCertFile)
	}

	srv := grpc.NewServer(opts...)

	gridClient := gridscaler.NewGridClient(cfg.httpTimeout)
	scaler := gridscaler.NewServer(gridClient, env, logr.FromSlogHandler(logger.Handler()))
	pb.RegisterExternalScalerServer(srv, scaler)

	healthSrv := health.NewServer()
	healthpb.RegisterHealthServer(srv, healthSrv)
	healthSrv.SetServingStatus("", healthpb.HealthCheckResponse_SERVING)

	lis, err := net.Listen("tcp", cfg.listenAddr)
	if err != nil {
		return err
	}

	// Graceful shutdown on SIGTERM/SIGINT.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, os.Interrupt)
	defer stop()

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("selenium-grid external scaler listening", "address", cfg.listenAddr, "gridUrlFromEnv", env["SE_GRID_URL"] != "")
		serveErr <- srv.Serve(lis)
	}()

	select {
	case <-ctx.Done():
		logger.Info("shutdown signal received, draining")
		healthSrv.SetServingStatus("", healthpb.HealthCheckResponse_NOT_SERVING)
		srv.GracefulStop()
		return nil
	case err := <-serveErr:
		if errors.Is(err, grpc.ErrServerStopped) {
			return nil
		}
		return err
	}
}

func collectGridEnv() map[string]string {
	env := make(map[string]string, len(gridEnvKeys))
	for _, k := range gridEnvKeys {
		if v := os.Getenv(k); v != "" {
			env[k] = v
		}
	}
	return env
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func envDurationOr(key string, fallback time.Duration) time.Duration {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	if d, err := time.ParseDuration(v); err == nil {
		return d
	}
	// Bare integer is interpreted as milliseconds, matching KEDA's timeout config.
	if ms, err := strconv.Atoi(v); err == nil {
		return time.Duration(ms) * time.Millisecond
	}
	return fallback
}
