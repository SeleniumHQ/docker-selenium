package gridscaler

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "github.com/SeleniumHQ/docker-selenium/keda-external-scaler/externalscaler"
)

// TestServer_GetMetrics_InvalidMetadata covers the metadata-parse error path of
// GetMetrics (missing url with no env fallback → InvalidArgument).
func TestServer_GetMetrics_InvalidMetadata(t *testing.T) {
	client := newTestClient(t, nil)
	_, err := client.GetMetrics(context.Background(), &pb.GetMetricsRequest{
		ScaledObjectRef: &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"browserName": "chrome"}},
		MetricName:      "selenium-grid-chrome",
	})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("GetMetrics() code = %v, want InvalidArgument", status.Code(err))
	}
}

// TestServer_GetMetrics_InvalidGridBody covers scrapeAndCount's
// getCountFromSeleniumResponse error path: a 200 response whose body is not the
// expected JSON must surface as Internal.
func TestServer_GetMetrics_InvalidGridBody(t *testing.T) {
	grid := fakeGrid(t, `this is not json`)
	client := newTestClient(t, nil)
	_, err := client.GetMetrics(context.Background(), &pb.GetMetricsRequest{
		ScaledObjectRef: &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"url": grid.URL, "browserName": "chrome"}},
		MetricName:      "selenium-grid-chrome",
	})
	if status.Code(err) != codes.Internal {
		t.Errorf("GetMetrics() code = %v, want Internal", status.Code(err))
	}
}

// TestServer_IsActive_InvalidMetadata covers IsActive's metadata-parse error
// path → InvalidArgument.
func TestServer_IsActive_InvalidMetadata(t *testing.T) {
	client := newTestClient(t, nil)
	_, err := client.IsActive(context.Background(), &pb.ScaledObjectRef{ScalerMetadata: map[string]string{"browserName": "chrome"}})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("IsActive() code = %v, want InvalidArgument", status.Code(err))
	}
}

// TestServer_IsActive_GridUnreachable covers IsActive's scrapeAndCount error
// path: an unreachable Grid → Internal.
func TestServer_IsActive_GridUnreachable(t *testing.T) {
	client := newTestClient(t, nil)
	_, err := client.IsActive(context.Background(), &pb.ScaledObjectRef{
		ScalerMetadata: map[string]string{"url": "http://192.0.2.1:4444/graphql", "browserName": "chrome"},
	})
	if status.Code(err) != codes.Internal {
		t.Errorf("IsActive() code = %v, want Internal", status.Code(err))
	}
}

// TestServer_IsActive_BelowActivationThreshold confirms IsActive reports false
// when the node count does not exceed activationThreshold. The fixture yields a
// count of 3, so a threshold of 3 must not activate.
func TestServer_IsActive_BelowActivationThreshold(t *testing.T) {
	grid := fakeGrid(t, fixtureGrid)
	client := newTestClient(t, nil)
	resp, err := client.IsActive(context.Background(), &pb.ScaledObjectRef{ScalerMetadata: map[string]string{
		"url":                 grid.URL,
		"browserName":         "chrome",
		"activationThreshold": "3",
	}})
	if err != nil {
		t.Fatalf("IsActive() error = %v", err)
	}
	if resp.Result {
		t.Error("IsActive() = true, want false (count 3 not > threshold 3)")
	}
}
