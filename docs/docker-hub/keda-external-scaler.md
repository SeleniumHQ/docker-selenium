---
description: KEDA external scaler that scales Selenium Grid from live session and queue state
---
# Selenium Grid KEDA External Scaler

### This image provides a standalone [KEDA external scaler](https://keda.sh/docs/latest/concepts/external-scalers/) for Selenium Grid. It is a gRPC server that reads the Grid's GraphQL state and tells KEDA how many browser Nodes it should scale to.

It is a functional extraction of KEDA's built-in `selenium-grid` scaler, so that Selenium's autoscaling logic can be released on the docker-selenium cadence instead of KEDA's. The scaling algorithm — capability matching (mirroring the Grid's `DefaultSlotMatcher`), slot reservation and the on-going session count conventions — is ported verbatim from upstream and is covered by KEDA's own test table.

## How it differs from the built-in scaler

The behaviour is identical. The only user-visible change is the trigger wiring:

| | Built-in | This external scaler |
|---|---|---|
| Trigger `type` | `selenium-grid` | `external` |
| `scalerAddress` | n/a | required — points at this scaler's Service |
| Grid URL / credentials | via `TriggerAuthentication` authParams | via trigger metadata, `*FromEnv`, or the scaler's own environment |

The credential difference matters: **KEDA does not forward `TriggerAuthentication` authParams to external scalers.** The Grid URL and credentials therefore have to reach the scaler another way (see below).

Use trigger type `external`, not `external-push` — the Grid exposes no push signal, so `StreamIsActive` is deliberately unimplemented.

## How to run this image

The Selenium Grid Helm chart wires this scaler up for you when `autoscaling.enabled=true`; see the chart [configuration](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/charts/selenium-grid/CONFIGURATION.md). To deploy it by hand:

```bash
docker pull selenium/keda-external-scaler:4.48.0-20260909
```

```yaml
# Deployment (excerpt) — the scaler serves gRPC on :8080
containers:
  - name: selenium-grid-scaler
    image: selenium/keda-external-scaler:4.48.0-20260909
    ports:
      - containerPort: 8080
    env:
      - name: SE_GRID_URL
        value: http://selenium-router:4444/graphql
    readinessProbe:
      grpc:
        port: 8080
```

```yaml
# ScaledObject / ScaledJob trigger (excerpt)
triggers:
  - type: external
    metadata:
      scalerAddress: selenium-grid-scaler.selenium.svc.cluster.local:8080
      url: http://selenium-router:4444/graphql
      browserName: chrome
      nodeMaxSessions: "1"
```

Reference manifests for both `ScaledObject` and `ScaledJob` live in [`.keda-external-scaler/deploy/`](https://github.com/SeleniumHQ/docker-selenium/tree/trunk/.keda-external-scaler/deploy). The scaler exposes the standard gRPC health service (`grpc.health.v1.Health`), so Kubernetes `grpc` probes work out of the box.

## Trigger metadata

All keys mirror the built-in scaler, plus `scalerAddress`, which KEDA consumes itself:

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
| `includeOngoingSessions` | `true` | count on-going sessions toward the metric |
| `authType` | `""` | `Basic` (default) or a bearer scheme such as `OAuth2` / `Bearer` |
| `username` / `password` | — | Grid basic auth |
| `accessToken` | — | Grid bearer token (with a non-`Basic` `authType`) |

Any key may also be supplied as `<key>FromEnv`, which KEDA resolves from the scale target's container environment before sending it.

### On-going sessions

The metric this scaler returns is the number of Nodes the Grid needs. On-going sessions are work the Grid is already serving, so whether they belong in that number depends on which count KEDA's executor already deducts for you:

| ScaledJob strategy | KEDA deducts | `includeOngoingSessions` | Metric emitted |
|---|---|---|---|
| `default` | running Job count | `true` (default) | queued requests + on-going sessions |
| `custom` | `customScalingRunningJobPercentage` of running Job count | `true` (default) | queued requests + on-going sessions |
| `accurate` | pending Job count | **`false`** | queued requests only |
| `eager` | running + pending Job count | **`false`** | queued requests only |
| _ScaledObject (HPA)_ | running replicas via HPA | `true` (default) | queued requests + on-going sessions |

`accurate` and `eager` never re-add running work, so counting on-going sessions there double-counts sessions already in progress and produces runaway Node creation that never scales back down. The Selenium Grid Helm chart derives this for you from `autoscaling.scaledJobOptions.scalingStrategy.strategy`; set `<node>.hpa.includeOngoingSessions` to override it.

## Authentication

Because authParams are not forwarded to external scalers, resolve the Grid URL and credentials by one of the following (highest precedence first, per key):

1. **Trigger metadata** — `url`, `username`, `password`, `accessToken` directly in the trigger `metadata`. Visible in the ScaledObject, so fine for the URL, best avoided for secrets.
2. **`*FromEnv` metadata** — for example `usernameFromEnv: SE_ROUTER_USERNAME`; KEDA resolves it from the **scale target's** container environment.
3. **Scaler environment** — mount the secret into this Deployment as `SE_GRID_URL`, `SE_GRID_AUTH_TYPE`, `SE_USERNAME`, `SE_PASSWORD`, `SE_ACCESS_TOKEN`. This keeps secrets out of the ScaledObject entirely.

## Runtime flags

| Flag | Environment variable | Default |
|---|---|---|
| `--listen-address` | `LISTEN_ADDRESS` | `:8080` |
| `--grid-http-timeout` | `SE_GRID_HTTP_TIMEOUT` | `3s` |
| `--tls-cert-file` | `TLS_CERT_FILE` | — |
| `--tls-key-file` | `TLS_KEY_FILE` | — |

Setting both TLS flags serves the gRPC endpoint over TLS; KEDA connects with `enableTLS` / `caCert` on its side.

## How to choose the correct tag for you

This image follows the same release convention as the other Grid components, so it is tagged with the Selenium Grid version:

```
selenium/keda-external-scaler-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```

### Example of a release with Selenium Grid Server <Major>.<Minor>.<Patch>, released on <YYYYMMDD>

```
    Selenium Server <Major>.<Minor>.<Patch>
    Release date <YYYYMMDD>


e126989f151e        selenium/keda-external-scaler   <Major>
e126989f151e        selenium/keda-external-scaler   <Major>.<Minor>
e126989f151e        selenium/keda-external-scaler   <Major>.<Minor>.<Patch>
e126989f151e        selenium/keda-external-scaler   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

Besides that, you also can use image tag `latest` or `nightly`.

Further reading: the scaler's own [README](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/.keda-external-scaler/README.md) and the Selenium Grid chart [configuration](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/charts/selenium-grid/CONFIGURATION.md).
