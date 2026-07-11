package gridscaler

import (
	"context"
	"strings"

	"github.com/go-logr/logr"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "github.com/SeleniumHQ/docker-selenium/keda-external-scaler/externalscaler"
)

// Server implements KEDA's externalscaler.ExternalScaler gRPC service for
// Selenium Grid. It is stateless per request: every RPC re-parses the trigger
// metadata KEDA sends and (for metric/active RPCs) re-queries the Grid.
type Server struct {
	pb.UnimplementedExternalScalerServer

	grid   *GridClient
	env    map[string]string
	logger logr.Logger
}

// NewServer returns a Server that queries the Grid via grid and resolves missing
// url/credentials from env (see parseMetadata precedence).
func NewServer(grid *GridClient, env map[string]string, logger logr.Logger) *Server {
	return &Server{grid: grid, env: env, logger: logger}
}

// GetMetricSpec returns the HPA metric spec: a deterministic metric name and the
// target value (1). KEDA adds/strips the trigger-index prefix itself.
func (s *Server) GetMetricSpec(_ context.Context, ref *pb.ScaledObjectRef) (*pb.GetMetricSpecResponse, error) {
	meta, err := parseMetadata(ref.GetScalerMetadata(), s.env)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "parsing scaler metadata: %s", err)
	}
	return &pb.GetMetricSpecResponse{
		MetricSpecs: []*pb.MetricSpec{{
			MetricName: buildMetricName(meta),
			TargetSize: meta.TargetValue,
		}},
	}, nil
}

// GetMetrics returns the number of Nodes the Grid needs for this trigger.
func (s *Server) GetMetrics(ctx context.Context, req *pb.GetMetricsRequest) (*pb.GetMetricsResponse, error) {
	meta, err := parseMetadata(req.GetScaledObjectRef().GetScalerMetadata(), s.env)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "parsing scaler metadata: %s", err)
	}
	count, err := s.scrapeAndCount(ctx, meta)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "querying selenium grid: %s", err)
	}
	return &pb.GetMetricsResponse{
		MetricValues: []*pb.MetricValue{{
			MetricName:  req.GetMetricName(),
			MetricValue: count,
		}},
	}, nil
}

// IsActive reports whether the trigger's node count exceeds activationThreshold.
func (s *Server) IsActive(ctx context.Context, ref *pb.ScaledObjectRef) (*pb.IsActiveResponse, error) {
	meta, err := parseMetadata(ref.GetScalerMetadata(), s.env)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "parsing scaler metadata: %s", err)
	}
	count, err := s.scrapeAndCount(ctx, meta)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "querying selenium grid: %s", err)
	}
	return &pb.IsActiveResponse{Result: count > meta.ActivationThreshold}, nil
}

// StreamIsActive is the push-scaler entrypoint. The Grid exposes no push signal,
// so only the polling `external` trigger type is supported.
func (s *Server) StreamIsActive(*pb.ScaledObjectRef, grpc.ServerStreamingServer[pb.IsActiveResponse]) error {
	return status.Error(codes.Unimplemented, "StreamIsActive is not supported; use KEDA trigger type 'external', not 'external-push'")
}

// scrapeAndCount queries the Grid and computes the node count for meta, applying
// the jobScalingStrategy convention: default/custom (and ScaledObjects) report
// queued requests plus on-going sessions; accurate/eager report queued requests
// only, to avoid double-counting in-progress work (SeleniumHQ/docker-selenium#3167).
func (s *Server) scrapeAndCount(ctx context.Context, meta *Metadata) (int64, error) {
	b, err := s.grid.Query(ctx, meta)
	if err != nil {
		return 0, err
	}
	newRequestNodes, onGoingSessions, err := getCountFromSeleniumResponse(
		b, meta.BrowserName, meta.BrowserVersion, meta.SessionBrowserName, meta.PlatformName,
		meta.NodeMaxSessions, meta.EnableManagedDownloads, meta.Capabilities, s.logger)
	if err != nil {
		return 0, err
	}
	count := newRequestNodes + onGoingSessions
	switch meta.JobScalingStrategy {
	case "accurate", "eager":
		count = newRequestNodes
	}
	return count, nil
}

// buildMetricName mirrors the built-in scaler's naming so HPA metric identity is
// preserved across migration: selenium-grid[-browser][-version][-platform],
// normalized to an HPA-safe string.
func buildMetricName(meta *Metadata) string {
	nameParts := []string{"selenium-grid"}
	if meta.BrowserName != "" {
		nameParts = append(nameParts, meta.BrowserName)
	}
	if meta.BrowserVersion != "" {
		nameParts = append(nameParts, meta.BrowserVersion)
	}
	if meta.PlatformName != "" {
		nameParts = append(nameParts, meta.PlatformName)
	}
	return normalizeString(strings.Join(nameParts, "-"))
}

// normalizeString replaces slashes, dots, colons, percent signs and parentheses
// with dashes, matching kedautil.NormalizeString.
func normalizeString(s string) string {
	replacer := strings.NewReplacer("/", "-", ".", "-", ":", "-", "%", "-", "(", "-", ")", "-")
	return replacer.Replace(s)
}
