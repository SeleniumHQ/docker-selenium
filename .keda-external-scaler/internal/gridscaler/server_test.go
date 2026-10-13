package gridscaler

import (
	"context"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-logr/logr"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	pb "github.com/SeleniumHQ/docker-selenium/keda-external-scaler/externalscaler"
)

// newTestClient starts the Server over an in-process bufconn gRPC connection and
// returns a client plus cleanup. env is the scaler-side environment fallback.
func newTestClient(t *testing.T, env map[string]string) pb.ExternalScalerClient {
	t.Helper()

	lis := bufconn.Listen(1024 * 1024)
	srv := grpc.NewServer()
	pb.RegisterExternalScalerServer(srv, NewServer(NewGridClient(3*time.Second), env, logr.Discard()))
	go func() { _ = srv.Serve(lis) }()

	conn, err := grpc.NewClient("passthrough:///bufnet",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return lis.DialContext(ctx)
		}),
		grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("grpc.NewClient() error = %v", err)
	}

	t.Cleanup(func() {
		_ = conn.Close()
		srv.Stop()
		_ = lis.Close()
	})
	return pb.NewExternalScalerClient(conn)
}

// fixtureGrid: 2 queued chrome requests + 1 on-going chrome session on a fully
// occupied Node → newRequestNodes=2, onGoingSessions=1. Same fixture as KEDA's
// Test_GetMetricsAndActivity_IncludeOngoingSessions.
const fixtureGrid = `{
	"data": {
		"grid": { "sessionCount": 1, "maxSession": 1, "totalSlots": 1 },
		"nodesInfo": {
			"nodes": [
				{
					"id": "node-1",
					"status": "UP",
					"sessionCount": 1,
					"maxSession": 1,
					"slotCount": 1,
					"stereotypes": "[{\"slots\": 1, \"stereotype\": {\"browserName\": \"chrome\"}}]",
					"sessions": [
						{
							"id": "session-1",
							"capabilities": "{\"browserName\": \"chrome\"}",
							"slot": { "id": "slot-1", "stereotype": "{\"browserName\": \"chrome\"}" }
						}
					]
				}
			]
		},
		"sessionsInfo": {
			"sessionQueueRequests": [
				"{\"browserName\": \"chrome\"}",
				"{\"browserName\": \"chrome\"}"
			]
		}
	}
}`

func fakeGrid(t *testing.T, body string) *httptest.Server {
	t.Helper()
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(body))
	}))
	t.Cleanup(server.Close)
	return server
}

// Ported from KEDA Test_GetMetricsAndActivity_IncludeOngoingSessions: unset and
// "true" include on-going sessions (3); "false" — the value required for the
// accurate and eager ScaledJob strategies — excludes them (2).
func TestServer_GetMetrics_IncludeOngoingSessions(t *testing.T) {
	grid := fakeGrid(t, fixtureGrid)
	client := newTestClient(t, nil)

	tests := []struct {
		name                   string
		includeOngoingSessions string
		wantMetric             int64
	}{
		{"unset defaults to including on-going sessions", "", 3},
		{"true includes on-going sessions", "true", 3},
		{"false excludes on-going sessions", "false", 2},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			meta := map[string]string{
				"url":         grid.URL,
				"browserName": "chrome",
			}
			if tt.includeOngoingSessions != "" {
				meta["includeOngoingSessions"] = tt.includeOngoingSessions
			}
			ref := &pb.ScaledObjectRef{ScalerMetadata: meta}

			metrics, err := client.GetMetrics(context.Background(), &pb.GetMetricsRequest{
				ScaledObjectRef: ref,
				MetricName:      "selenium-grid-chrome",
			})
			if err != nil {
				t.Fatalf("GetMetrics() error = %v", err)
			}
			if got := metrics.MetricValues[0].MetricValue; got != tt.wantMetric {
				t.Errorf("GetMetrics() = %d, want %d", got, tt.wantMetric)
			}

			active, err := client.IsActive(context.Background(), ref)
			if err != nil {
				t.Fatalf("IsActive() error = %v", err)
			}
			if !active.Result {
				t.Error("IsActive() = false, want true")
			}
		})
	}
}

func TestServer_GetMetricSpec(t *testing.T) {
	client := newTestClient(t, nil)

	tests := []struct {
		name string
		meta map[string]string
		want string
	}{
		{"browser only", map[string]string{"url": "http://g", "browserName": "chrome"}, "selenium-grid-chrome"},
		{
			"browser, version, platform normalized",
			map[string]string{"url": "http://g", "browserName": "chrome", "browserVersion": "131.0", "platformName": "linux"},
			"selenium-grid-chrome-131-0-linux",
		},
		{"no browser", map[string]string{"url": "http://g"}, "selenium-grid"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			resp, err := client.GetMetricSpec(context.Background(), &pb.ScaledObjectRef{ScalerMetadata: tt.meta})
			if err != nil {
				t.Fatalf("GetMetricSpec() error = %v", err)
			}
			if got := resp.MetricSpecs[0].MetricName; got != tt.want {
				t.Errorf("metric name = %q, want %q", got, tt.want)
			}
			if got := resp.MetricSpecs[0].TargetSize; got != 1 {
				t.Errorf("targetSize = %d, want 1", got)
			}
		})
	}
}

func TestServer_InvalidMetadata(t *testing.T) {
	client := newTestClient(t, nil)
	// Missing url and no env fallback → InvalidArgument.
	_, err := client.GetMetricSpec(context.Background(), &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"browserName": "chrome"}})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("GetMetricSpec() code = %v, want InvalidArgument", status.Code(err))
	}
}

func TestServer_GridUnreachable(t *testing.T) {
	client := newTestClient(t, nil)
	// Reserved TEST-NET-1 address with a closed port → connection error → Internal.
	_, err := client.GetMetrics(context.Background(), &pb.GetMetricsRequest{
		ScaledObjectRef: &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"url": "http://192.0.2.1:4444/graphql", "browserName": "chrome"}},
		MetricName:      "selenium-grid-chrome",
	})
	if status.Code(err) != codes.Internal {
		t.Errorf("GetMetrics() code = %v, want Internal", status.Code(err))
	}
}

func TestServer_StreamIsActive_Unimplemented(t *testing.T) {
	client := newTestClient(t, nil)
	stream, err := client.StreamIsActive(context.Background(), &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"url": "http://g", "browserName": "chrome"}})
	if err != nil {
		t.Fatalf("StreamIsActive() setup error = %v", err)
	}
	_, err = stream.Recv()
	if status.Code(err) != codes.Unimplemented {
		t.Errorf("StreamIsActive() code = %v, want Unimplemented", status.Code(err))
	}
}

func TestServer_EnvFallback(t *testing.T) {
	grid := fakeGrid(t, fixtureGrid)
	// url comes from the scaler environment, not trigger metadata.
	client := newTestClient(t, map[string]string{"SE_GRID_URL": grid.URL})
	metrics, err := client.GetMetrics(context.Background(), &pb.GetMetricsRequest{
		ScaledObjectRef: &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"browserName": "chrome"}},
		MetricName:      "selenium-grid-chrome",
	})
	if err != nil {
		t.Fatalf("GetMetrics() error = %v", err)
	}
	if got := metrics.MetricValues[0].MetricValue; got != 3 {
		t.Errorf("GetMetrics() = %d, want 3", got)
	}
}
