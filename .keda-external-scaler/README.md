# Selenium Grid KEDA External Scaler

A standalone [KEDA external scaler](https://keda.sh/docs/latest/concepts/external-scalers/)
for Selenium Grid. It is a gRPC server that translates the Grid's GraphQL state
into the number of browser Nodes KEDA should scale to.

This is a functional extraction of KEDA's built-in `selenium-grid` scaler
(`kedacore/keda/pkg/scalers/selenium_grid_scaler.go`), so that Selenium's
autoscaling logic can be released on the docker-selenium cadence instead of
KEDA's. The scaling algorithm — capability matching (mirroring Grid's
`DefaultSlotMatcher`), slot reservation, and the per-`jobScalingStrategy` count
conventions — is ported verbatim and covered by KEDA's own upstream test table.

## How it differs from the built-in scaler

Behaviour is identical. The only user-visible change is the trigger wiring:

| | Built-in | External scaler |
|---|---|---|
| Trigger `type` | `selenium-grid` | `external` |
| `scalerAddress` | n/a | required — points at this scaler's Service |
| Grid URL / credentials | via `TriggerAuthentication` authParams | via trigger metadata, `*FromEnv`, or the scaler's env |

The credential difference is the important one: **KEDA does not forward
`TriggerAuthentication` authParams to external scalers.** The Grid URL and
credentials must therefore reach the scaler another way (see [Authentication](#authentication)).

## Metadata

All keys mirror the built-in scaler, plus `scalerAddress` (consumed by KEDA, not
the scaler):

| Key | Default | Notes |
|---|---|---|
| `scalerAddress` | — | KEDA-side; `host:port` of this scaler's Service |
| `url` | — | Grid GraphQL endpoint; required (metadata, `urlFromEnv`, or `SE_GRID_URL`) |
| `browserName` | `""` | e.g. `chrome`, `firefox`, `MicrosoftEdge` |
| `sessionBrowserName` | = `browserName` | e.g. `msedge` for Edge |
| `browserVersion` | `""` | prefix-matched against requests |
| `platformName` | `""` | platform-family aware |
| `capabilities` | `""` | JSON of extra required capabilities |
| `nodeMaxSessions` | `1` | slots per Node |
| `enableManagedDownloads` | `true` | |
| `activationThreshold` | `0` | scale-from-zero threshold |
| `unsafeSsl` | `false` | skip Grid TLS verification |
| `jobScalingStrategy` | `default` | `default`\|`custom`\|`accurate`\|`eager`; must match the ScaledJob's `scalingStrategy.strategy` |
| `authType` | `""` | `Basic` (default) or a bearer scheme like `OAuth2`/`Bearer` |
| `username` / `password` | — | Grid basic auth |
| `accessToken` | — | Grid bearer token (with non-Basic `authType`) |

Any key may also be supplied as `<key>FromEnv` (KEDA resolves it from the scale
target's container env before sending).

## Authentication

Because authParams are not forwarded, resolve Grid URL and credentials by one of
(precedence high → low, per key):

1. **Trigger metadata** — `url`, `username`, `password`, `accessToken` directly
   in the trigger `metadata` (visible in the ScaledObject; fine for URL, avoid
   for secrets).
2. **`*FromEnv` metadata** — e.g. `usernameFromEnv: SE_ROUTER_USERNAME`; KEDA
   resolves it from the **scale target's** container environment.
3. **Scaler environment** — mount the secret into *this* Deployment as
   `SE_GRID_URL`, `SE_GRID_AUTH_TYPE`, `SE_USERNAME`, `SE_PASSWORD`,
   `SE_ACCESS_TOKEN`. Keeps secrets out of the ScaledObject entirely.

Options 2 and 3 are both supported; pick per your secret-management preference.

## Deploy

```bash
kubectl apply -f deploy/deployment.yaml          # scaler Deployment + Service
kubectl apply -f deploy/scaledjob-example.yaml   # or scaledobject-example.yaml
```

See `deploy/` for full examples. The scaler exposes a gRPC health service
(`grpc.health.v1.Health`) for Kubernetes `grpc` probes.

## Build & test

```bash
make build     # -> bin/selenium-grid-scaler
make test      # go test ./... -race -cover  (includes the verbatim upstream table)
make image     # multi-arch (linux/amd64, linux/arm64) selenium/keda-external-scaler
make proto     # regenerate gRPC stubs (only needed if proto/externalscaler.proto changes)
```

Runtime flags (all also configurable by env):

| Flag | Env | Default |
|---|---|---|
| `--listen-address` | `LISTEN_ADDRESS` | `:8080` |
| `--grid-http-timeout` | `SE_GRID_HTTP_TIMEOUT` | `3s` |
| `--tls-cert-file` | `TLS_CERT_FILE` | — |
| `--tls-key-file` | `TLS_KEY_FILE` | — |

Setting both TLS flags serves the gRPC endpoint over TLS (KEDA connects with
`enableTLS`/`caCert` on its side).

Requires Go 1.26+ (matching the `go` directive in `go.mod`).

## Layout

```
proto/externalscaler.proto   vendored from KEDA, byte-identical
externalscaler/              generated gRPC stubs (committed)
internal/gridscaler/         logic (ported), metadata, grid client, gRPC server
cmd/scaler/                  binary entrypoint
deploy/                      reference manifests
```

Only `StreamIsActive` (the `external-push` entrypoint) is unimplemented — the
Grid exposes no push signal, so use trigger type `external`, not `external-push`.
