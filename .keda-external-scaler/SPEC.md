# Spec: Selenium Grid KEDA External Scaler

## Objective

Extract the KEDA built-in `selenium-grid` scaler (currently maintained in-tree at
`kedacore/keda/pkg/scalers/selenium_grid_scaler.go`, mirrored in this repo at
`.keda/scalers/selenium_grid_scaler.go`) into a standalone **KEDA external scaler**:
a gRPC server implementing KEDA's `externalscaler.ExternalScaler` service, owned and
released by the SeleniumHQ/docker-selenium project.

**Why:**
- Decouple scaler releases from the KEDA release cadence — bug fixes (e.g. the
  accurate/eager double-counting fix, SeleniumHQ/docker-selenium#3167) ship when
  docker-selenium ships, not months later in a KEDA minor.
- The Selenium project controls the full autoscaling stack (Grid, chart, scaler)
  and can evolve capability-matching logic in lockstep with Grid's
  `DefaultSlotMatcher`.
- Users get identical scaling behavior; only the trigger wiring in the
  ScaledObject/ScaledJob changes from `type: selenium-grid` to `type: external`.

**Who:** operators running Selenium Grid on Kubernetes with KEDA (ScaledJob or
ScaledObject per browser stereotype), primarily via the `selenium-grid` Helm chart
in `charts/`.

**Success looks like:** a container image that, deployed next to the Grid, answers
KEDA's `GetMetricSpec`/`GetMetrics`/`IsActive` with values byte-for-byte equal to
what the built-in scaler would report for the same Grid GraphQL state and the same
trigger metadata.

## Background: how the two sides work today

### KEDA external scaler contract (from `pkg/scalers/externalscaler/externalscaler.proto`)

```proto
service ExternalScaler {
    rpc IsActive(ScaledObjectRef) returns (IsActiveResponse) {}
    rpc StreamIsActive(ScaledObjectRef) returns (stream IsActiveResponse) {}   // only used by trigger type `external-push`
    rpc GetMetricSpec(ScaledObjectRef) returns (GetMetricSpecResponse) {}
    rpc GetMetrics(GetMetricsRequest) returns (GetMetricsResponse) {}
}
message ScaledObjectRef { string name; string namespace; map<string,string> scalerMetadata; }
```

Facts that constrain the design (verified in `pkg/scalers/external_scaler.go`):

1. **Only `triggerMetadata` reaches the external scaler.** KEDA copies
   `config.TriggerMetadata` into `scalerMetadata`; keys ending in `FromEnv` are
   resolved against the scale target's container env before sending.
   **TriggerAuthentication `authParams` are NOT forwarded.** Grid credentials
   therefore cannot arrive via TriggerAuthentication — they must come from
   `*FromEnv` trigger metadata or from the scaler's own environment/mounted secret.
2. KEDA calls `GetMetrics` then `IsActive` on every poll (`pollingInterval`);
   the server should be stateless per request and cheap to call.
3. `MetricValue`/`TargetSize` int64 fields are honored when the float fields are 0,
   so integer node counts can be returned via the int64 fields safely.
4. KEDA⇄scaler transport supports TLS/mTLS configured on the KEDA side
   (`enableTLS`, `caCert`, `tlsClientCert`, `tlsClientKey` authParams). The server
   must optionally serve TLS to support this.
5. `metricName` returned by `GetMetricSpec` is echoed back in `GetMetricsRequest`
   without the `sX-` trigger index prefix; the server must generate a
   deterministic, HPA-safe metric name and dedupe across triggers via its own
   naming (same scheme as built-in: `selenium-grid[-browserName][-browserVersion][-platformName]`).

### Built-in scaler logic to port (from `selenium_grid_scaler.go`)

All of the following moves verbatim (it is pure functions over the GraphQL
response — already mirrored at `.keda/scalers/selenium_grid_scaler.go`):

- GraphQL POST query: `{ grid { sessionCount, maxSession, totalSlots }, nodesInfo { nodes { ... } }, sessionsInfo { sessionQueueRequests } }`
- Auth on the Grid request: Basic (username/password) or `Authorization: <authType> <accessToken>`
- Capability matching following Grid's `DefaultSlotMatcher`:
  `checkRequestCapabilitiesMatch`, `checkStereotypeCapabilitiesMatch`,
  extension-capability filtering (`goog:`, `moz:`, `ms:`, `se:` prefixes),
  `se:downloadsEnabled` handling, platform-family matching (`GetPlatform`,
  `isSameFamily`, the full Platform table)
- The reservation algorithm in `getCountFromSeleniumResponse`: walk queued
  requests, reserve free matching slots on existing UP nodes, then pack remaining
  requests onto hypothetical new nodes of capacity `nodeMaxSessions`; also count
  matching ongoing sessions
- The metric convention per `jobScalingStrategy`:
  - `default`/`custom` (and all ScaledObjects): `count = newRequestNodes + onGoingSessions`
  - `accurate`/`eager`: `count = newRequestNodes`
- Activation: `count > activationThreshold`

## Tech Stack

- Go (match KEDA's toolchain era: go 1.24+; module independent of `kedacore/keda`)
- `google.golang.org/grpc` + `google.golang.org/protobuf` (generated stubs from a
  vendored copy of `externalscaler.proto` — proto is stable and versionless)
- `grpc_health_v1` health service for k8s liveness/readiness probes
- Zero KEDA imports: the only KEDA coupling is the proto contract
- Container image: distroless/static or scratch, multi-arch (amd64/arm64),
  built from a Dockerfile in this directory

## Commands

```
Generate stubs: make proto        # protoc + protoc-gen-go/protoc-gen-go-grpc pinned versions
Build:          make build        # go build ./... → bin/selenium-grid-scaler
Test:           make test         # go test ./... -race -cover
Lint:           make lint         # golangci-lint run
Image:          make image        # docker buildx build -t selenium/keda-external-scaler:<tag>
Run locally:    bin/selenium-grid-scaler --port 8080   # env: SE_GRID_URL, SE_USERNAME, ...
```

(Exact Makefile targets created in the implementation phase; commands above are
the contract.)

## Project Structure

```
.keda-external-scaler/
├── SPEC.md                      → this document
├── go.mod / go.sum              → module github.com/SeleniumHQ/docker-selenium/keda-external-scaler
├── Makefile
├── Dockerfile
├── proto/
│   └── externalscaler.proto     → vendored from kedacore/keda (unchanged)
├── externalscaler/              → generated pb.go + grpc.pb.go (committed)
├── cmd/scaler/
│   └── main.go                  → flag/env parsing, gRPC server + health service, TLS setup
├── internal/gridscaler/
│   ├── metadata.go              → parse scalerMetadata map → typed config (defaults, validation)
│   ├── grid_client.go           → GraphQL query + auth against the Grid
│   ├── logic.go                 → ported matching + reservation algorithm (pure functions)
│   ├── platform.go              → Platform table, GetPlatform, isSameFamily
│   └── server.go                → ExternalScaler service impl (IsActive/GetMetricSpec/GetMetrics; StreamIsActive → Unimplemented)
├── internal/gridscaler/*_test.go → ported + new unit tests
└── deploy/
    ├── deployment.yaml          → reference Deployment + Service
    └── scaledjob-example.yaml   → example ScaledJob/ScaledObject with `type: external` trigger
```

## Trigger metadata contract (user-facing)

Same keys as the built-in scaler so migration is mechanical, plus `scalerAddress`
(consumed by KEDA itself, not the server):

```yaml
triggers:
  - type: external
    metadata:
      scalerAddress: selenium-grid-scaler.selenium.svc:8080   # KEDA-side
      url: http://selenium-hub.selenium.svc:4444/graphql
      browserName: chrome
      sessionBrowserName: chrome        # optional, defaults to browserName
      browserVersion: "131.0"           # optional
      platformName: linux               # optional
      capabilities: '{"myApp:version":"beta"}'   # optional JSON
      nodeMaxSessions: "1"
      enableManagedDownloads: "true"
      activationThreshold: "0"
      unsafeSsl: "false"                # Grid TLS verification
      jobScalingStrategy: default       # default|custom|accurate|eager
      authType: Basic                   # optional
      usernameFromEnv: SE_USERNAME      # resolved by KEDA from scale-target env
      passwordFromEnv: SE_PASSWORD
      # accessTokenFromEnv: SE_ACCESS_TOKEN
```

Server-side fallbacks (because authParams aren't forwarded): if `url`/credentials
are absent from `scalerMetadata`, the server falls back to its own env
(`SE_GRID_URL`, `SE_GRID_AUTH_TYPE`, `SE_USERNAME`, `SE_PASSWORD`,
`SE_ACCESS_TOKEN`), so operators can keep secrets out of trigger metadata
entirely by mounting them into the scaler Deployment.

All values arrive as strings in the map; the server performs the same
defaulting/validation the `keda:` struct tags did (`nodeMaxSessions=1`,
`enableManagedDownloads=true`, `jobScalingStrategy∈{default,custom,accurate,eager}`,
`sessionBrowserName←browserName`).

## Code Style

Match the existing ported file `.keda/scalers/selenium_grid_scaler.go` — same
function names, same comment style — so diffs against upstream KEDA stay
reviewable. Example of the target shape for the server layer:

```go
// GetMetrics implements externalscaler.ExternalScalerServer.
func (s *Server) GetMetrics(ctx context.Context, req *pb.GetMetricsRequest) (*pb.GetMetricsResponse, error) {
    meta, err := parseMetadata(req.ScaledObjectRef.ScalerMetadata, s.envDefaults)
    if err != nil {
        return nil, status.Errorf(codes.InvalidArgument, "parsing scaler metadata: %s", err)
    }
    count, _, err := s.scrapeAndCount(ctx, meta)
    if err != nil {
        return nil, status.Errorf(codes.Internal, "querying selenium grid: %s", err)
    }
    return &pb.GetMetricsResponse{MetricValues: []*pb.MetricValue{{
        MetricName: buildMetricName(meta), MetricValue: count,
    }}}, nil
}
```

Conventions: gRPC status codes for errors (InvalidArgument for bad metadata,
Internal/Unavailable for Grid failures); `logr`-style or stdlib `slog` structured
logging; no global mutable state except an HTTP client cache keyed by
(url, unsafeSsl).

## Testing Strategy

- **Unit tests (primary):** port `selenium_grid_scaler_test.go` (≈4000 lines of
  table-driven cases in KEDA, already mirrored in `.keda/scalers/`) against the
  ported `logic.go`/`metadata.go`. These tests are the parity proof — they must
  pass unmodified in their expectations.
- **Server tests:** in-process gRPC server + `httptest` fake Grid GraphQL
  endpoint; assert GetMetricSpec/GetMetrics/IsActive responses for representative
  metadata, including `*FromEnv`-resolved values and env fallbacks, auth header
  propagation, and error mapping.
- **StreamIsActive test:** assert it returns gRPC `Unimplemented`.
- Coverage expectation: `internal/gridscaler` ≥ the upstream file's effective
  coverage; `go test -race` clean.
- **E2E (follow-up, out of initial scope):** wire into this repo's existing
  `tests/` K8s autoscaling suite behind a flag that swaps the chart trigger to
  `type: external`.

## Boundaries

- **Always:** run `make test` before commit; keep `logic.go`/`platform.go`
  semantically identical to `.keda/scalers/selenium_grid_scaler.go` (divergence
  is a spec change); keep the vendored proto byte-identical to upstream KEDA;
  return gRPC status errors, never panic on malformed metadata.
- **Ask first:** adding third-party dependencies beyond grpc/protobuf; changing
  the metric-name scheme or metadata keys (breaks migration parity); modifying
  the Helm chart in `charts/` (separate change); publishing image names/registries.
- **Never:** commit Grid credentials or TLS keys; edit generated `*.pb.go` by
  hand; remove or weaken ported test expectations to make them pass; couple the
  module to `github.com/kedacore/keda/v2`.

## Success Criteria

1. `go test ./... -race` passes, including the full ported upstream test table
   with unmodified expected values.
2. A local run against a fake Grid returns, for the documented example metadata,
   the same `(metricValue, isActive)` pairs as the built-in scaler computes for
   the same GraphQL fixture (verified by the shared test table).
3. `GetMetricSpec` returns `selenium-grid[-browser][-version][-platform]` with
   `targetSize: 1`, matching the built-in naming after KEDA strips the index prefix.
4. All four `jobScalingStrategy` values produce the two documented count
   conventions (`+onGoingSessions` vs queue-only).
5. Missing/invalid metadata yields `InvalidArgument`; Grid unreachable yields a
   non-OK status and KEDA logs it without crashing the server.
6. `deploy/` manifests bring up the scaler and a ScaledJob example that KEDA
   accepts (validated against a kind cluster manually or in follow-up e2e).
7. Image builds for linux/amd64 + linux/arm64.

## Resolved Decisions

1. **Auth path:** support BOTH `*FromEnv` trigger metadata and scaler-side
   env/secret mount; document both, trigger metadata takes precedence over
   server env when both are present.
2. **Image name:** `selenium/keda-external-scaler`; module path
   `github.com/SeleniumHQ/docker-selenium/keda-external-scaler`.
3. **`StreamIsActive`:** returns gRPC `Unimplemented`. Only the polling
   `external` trigger type is supported; `external-push` is out of scope.

## Open Questions

1. **Helm chart integration** (`charts/selenium-grid` switching trigger type to
   `external` and deploying the scaler): separate spec/PR, correct?
2. **Deprecation story** for the KEDA built-in scaler (upstream KEDA deprecation
   PR + migration doc): in scope for this effort or tracked separately?
