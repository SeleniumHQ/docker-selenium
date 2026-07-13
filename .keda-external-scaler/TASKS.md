# Tasks: Selenium Grid KEDA External Scaler

Phase 3 of the spec-driven workflow. Ordered by dependency; T2/T4/T5 may run in
parallel after T1. See [PLAN.md](PLAN.md) for rationale.

- [ ] **T1: Module scaffold + generated gRPC stubs**
  - Acceptance: `go build ./...` succeeds from a clean checkout with no protoc
    installed; `proto/externalscaler.proto` is byte-identical to
    `kedacore/keda/pkg/scalers/externalscaler/externalscaler.proto`.
  - Verify: `make build` (and `make proto` regenerates with zero diff).
  - Files: `go.mod`, `Makefile`, `proto/externalscaler.proto`,
    `externalscaler/externalscaler.pb.go`, `externalscaler/externalscaler_grpc.pb.go`

- [ ] **T2: Port pure scaling logic**
  - Acceptance: `getCountFromSeleniumResponse`, capability/stereotype matching,
    platform table, and reservation algorithm compile standalone with no KEDA
    imports; function names and comments match `.keda/scalers/selenium_grid_scaler.go`.
  - Verify: `go vet ./...` + compiles; behavior verified by T3.
  - Files: `internal/gridscaler/types.go`, `internal/gridscaler/logic.go`,
    `internal/gridscaler/platform.go`

- [ ] **T3: Port upstream unit test table (parity gate 1)**
  - Acceptance: all `getCountFromSeleniumResponse` test cases from upstream
    `selenium_grid_scaler_test.go` pass with **unmodified expected values**;
    only harness/setup code adapted.
  - Verify: `go test ./internal/gridscaler -run TestGetCount -race`
  - Files: `internal/gridscaler/logic_test.go`

- [ ] **T4: Metadata parsing with env fallback**
  - Acceptance: `parseMetadata(map[string]string, envDefaults)` reproduces the
    `keda:` tag behavior (defaults `nodeMaxSessions=1`,
    `enableManagedDownloads=true`, `jobScalingStrategy` enum validation,
    `sessionBrowserName←browserName`, required `url`); strips `FromEnv` key
    suffixes; precedence `<name>` > `<name>FromEnv` > `SE_*` server env.
  - Verify: `go test ./internal/gridscaler -run TestParseMetadata`
  - Files: `internal/gridscaler/metadata.go`, `internal/gridscaler/metadata_test.go`

- [ ] **T5: Grid GraphQL client**
  - Acceptance: same GraphQL query string as built-in; Basic auth when
    authType empty/Basic + username/password set, else
    `Authorization: <authType> <accessToken>`; non-200 → error; cached
    `*http.Client` per `unsafeSsl`; configurable timeout (default 3s).
  - Verify: `go test ./internal/gridscaler -run TestGridClient` (httptest server
    asserting body, headers, TLS-skip behavior)
  - Files: `internal/gridscaler/grid_client.go`, `internal/gridscaler/grid_client_test.go`

- [ ] **T6: gRPC server implementation (parity gate 2)**
  - Acceptance: `GetMetricSpec` returns normalized
    `selenium-grid[-browser][-version][-platform]` with `targetSize=1`;
    `GetMetrics` returns count per `jobScalingStrategy` convention; `IsActive`
    returns `count > activationThreshold`; `StreamIsActive` returns
    `Unimplemented`; bad metadata → `InvalidArgument`, Grid failure → `Internal`.
  - Verify: `go test ./internal/gridscaler -run TestServer -race` (in-process
    grpc server + fake Grid fixtures covering all four strategies)
  - Files: `internal/gridscaler/server.go`, `internal/gridscaler/server_test.go`

- [ ] **T7: Binary entrypoint**
  - Acceptance: flags/env for port (default 8080), Grid env fallbacks
    (`SE_GRID_URL`, `SE_GRID_AUTH_TYPE`, `SE_USERNAME`, `SE_PASSWORD`,
    `SE_ACCESS_TOKEN`), HTTP timeout, optional TLS (`--tls-cert-file`,
    `--tls-key-file`); registers grpc_health_v1; graceful shutdown on
    SIGTERM/SIGINT; structured logging (slog).
  - Verify: `make build`; smoke: start binary, `grpc_health_probe`/grpcurl
    health check returns SERVING.
  - Files: `cmd/scaler/main.go`

- [ ] **T8: Container image**
  - Acceptance: multi-stage Dockerfile → distroless/static nonroot; image name
    `selenium/keda-external-scaler`; builds linux/amd64 and linux/arm64.
  - Verify: `make image`; `docker run` starts and health check passes.
  - Files: `Dockerfile`, `Makefile` (image target), `.dockerignore`

- [ ] **T9: Deployment manifests + docs**
  - Acceptance: reference Deployment+Service; example ScaledJob and ScaledObject
    using `type: external` with the documented metadata; README covering both
    auth paths (FromEnv metadata and scaler-side secret mount), migration table
    from `type: selenium-grid`, and KEDA-side TLS notes.
  - Verify: manifests pass `kubectl apply --dry-run=client`; README reviewed
    against SPEC trigger-metadata contract.
  - Files: `deploy/deployment.yaml`, `deploy/scaledjob-example.yaml`,
    `deploy/scaledobject-example.yaml`, `README.md`
