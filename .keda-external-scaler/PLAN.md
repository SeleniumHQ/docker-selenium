# Plan: Selenium Grid KEDA External Scaler

Implements [SPEC.md](SPEC.md). Phase 2 of the spec-driven workflow.

## Components and dependency order

```
T1 scaffold (go.mod, vendored proto, generated stubs, Makefile)
 ├── T2 ported pure logic (platform.go, logic.go, types.go)
 │     └── T3 ported upstream test table  ← parity gate #1
 ├── T4 metadata parsing (map → typed config, env fallback)
 └── T5 grid client (GraphQL + auth)
        └── T6 gRPC server (needs T2–T5)  ← parity gate #2
              └── T7 main.go (TLS, health, shutdown)
                    ├── T8 Dockerfile / image
                    └── T9 deploy manifests + README
```

T2/T4/T5 are independent of each other and can proceed in parallel after T1.
Everything downstream of T6 is sequential.

## Implementation order rationale

1. **Scaffold first (T1)** — everything compiles against the generated
   `externalscaler` stubs; committing generated code makes builds hermetic
   (no protoc needed for `go build`).
2. **Logic port + its tests immediately after (T2, T3)** — this is the only
   part where silent divergence from upstream is possible. Locking it behind
   the unmodified upstream test table before writing any new code means later
   work cannot mask a porting mistake.
3. **Metadata and grid client (T4, T5)** are new code (the built-in scaler got
   these for free from KEDA's `keda:` struct tags and `kedautil.CreateHTTPClient`);
   they get their own dedicated tests rather than ported ones.
4. **Server (T6)** is thin glue; testing it in-process with a fake Grid gives an
   end-to-end parity check without Kubernetes.
5. **Packaging (T7–T9)** last, once behavior is proven.

## Key design decisions carried into implementation

- **`FromEnv` key normalization:** KEDA sends resolved values but keeps the
  original key, e.g. `scalerMetadata["usernameFromEnv"] = "<resolved value>"`
  (see `parseExternalScalerMetadata` in KEDA). The metadata parser must strip a
  `FromEnv` suffix and treat the key as its base name. Precedence per key:
  `<name>` > `<name>FromEnv` > server env fallback (`SE_*`).
- **Metric naming:** replicate `kedautil.NormalizeString` (lowercase, non
  `[a-zA-Z0-9-]` → `-`) locally so `GetMetricSpec` names match the built-in
  scheme `selenium-grid[-browser][-version][-platform]`. KEDA adds/strips the
  `sX-` index prefix itself; the server never sees it.
- **HTTP client reuse:** cache `*http.Client` keyed by `unsafeSsl` only (timeout
  fixed via flag, default 3s like KEDA's `GlobalHTTPTimeout` default); avoids a
  new TLS handshake per poll.
- **Error mapping:** metadata problems → `codes.InvalidArgument`; Grid
  unreachable/non-200/bad JSON → `codes.Internal`. `StreamIsActive` →
  `codes.Unimplemented` (per resolved decision #3).
- **`IsActive` does its own Grid query** (KEDA calls GetMetrics then IsActive
  back-to-back; a shared 1-poll-interval cache is a possible later optimization,
  not in scope — correctness over cleverness first).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Upstream test file (~4k lines) imports KEDA internals (`scalersconfig`, logr) | Only the test harness (constructor/setup) is adapted; every `expected*` value stays byte-identical. T3 acceptance forbids touching expectations. |
| `keda:` struct-tag parser subtleties (defaults, enum validation, optional/required) lost in hand-written parser | T4 includes parse tests mirroring the upstream metadata test cases (`parseSeleniumGridScalerMetadata` table) plus new FromEnv/fallback cases. |
| Metric name mismatch breaks HPA continuity during migration | Explicit unit test comparing generated names against known built-in outputs for the chart's standard triggers (chrome/firefox/edge). |
| gRPC/protobuf version drift vs generated code | Pin protoc-gen-go/protoc-gen-go-grpc versions in Makefile; commit generated code. |
| KEDA-side TLS (`enableTLS`, mTLS) untestable without KEDA | Serve standard TLS via flags; verify with an in-test TLS client; document that KEDA-side certs are the operator's existing external-scaler mechanics. |

## Verification checkpoints

- **Gate 1 (after T3):** `go test ./internal/gridscaler` green with unmodified
  upstream expectations → algorithm parity proven.
- **Gate 2 (after T6):** in-process gRPC + fake Grid fixture test green,
  including both `includeOngoingSessions` conventions and activation threshold →
  wire-level parity proven.
- **Gate 3 (after T8):** `make image` builds linux/amd64+arm64; container starts
  and serves health check.
- **Final:** manual kind-cluster smoke with `deploy/` manifests (documented in
  README; automated e2e is follow-up per spec).
