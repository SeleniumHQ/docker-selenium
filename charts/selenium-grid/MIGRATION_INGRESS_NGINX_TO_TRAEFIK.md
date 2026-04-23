# Migration Notes: Ingress NGINX -> Traefik

This document summarizes configuration changes introduced

- https://github.com/SeleniumHQ/docker-selenium/pull/3083
- Title: `K8s: Replace Ingress NGINX with Traefik for default ingress controller`
- Date: `2026-02-21`

## 1. Dependency changes

In `charts/selenium-grid/Chart.yaml`:

- Removed dependency:
  - `ingress-nginx` from `https://kubernetes.github.io/ingress-nginx`
  - condition: `ingress.enableWithController, ingress-nginx.enabled`
- Added dependency:
  - `traefik` from `https://traefik.github.io/charts`
  - version: `^39.0.0`
  - condition: `ingress.enableWithController, traefik.enabled`

## 2. Values schema changes

### 2.1 Removed `ingress.nginx.*` keys

All NGINX-specific ingress keys were removed:

- `ingress.nginx.websocket`
- `ingress.nginx.proxyTimeout`
- `ingress.nginx.proxyBuffer.size`
- `ingress.nginx.proxyBuffer.number`
- `ingress.nginx.sslPassthrough`
- `ingress.nginx.sslSecret`
- `ingress.nginx.useHttp2`
- `ingress.nginx.upstreamKeepalive.connections`
- `ingress.nginx.upstreamKeepalive.time`
- `ingress.nginx.upstreamKeepalive.requests`

### 2.2 Added `ingress.traefik.*` keys

New Traefik-focused keys (from `values.yaml` in the commit):

- `ingress.traefik.enabled: true`
- `ingress.traefik.entryPoints: ""`
- `ingress.traefik.middlewares: ""`
- `ingress.traefik.priority: ""`
- `ingress.traefik.pathMatcher: "PathPrefix"`
- `ingress.traefik.tls.enabled: true`
- `ingress.traefik.tls.options: ""`
- `ingress.traefik.tls.certResolver: ""`
- `ingress.traefik.service.useHttpsScheme: true`
- `ingress.traefik.service.sticky.cookie.enabled: false`
- `ingress.traefik.serversTransport.enabled: true`
- `ingress.traefik.serversTransport.nameOverride: ""`
- `ingress.traefik.serversTransport.reference: ""`
- `ingress.traefik.serversTransport.spec.insecureSkipVerify: true`
- `ingress.traefik.serversTransport.spec.disableHTTP2: true`
- `ingress.traefik.serversTransport.spec.forwardingTimeouts.dialTimeout: "3600s"`
- `ingress.traefik.serversTransport.spec.forwardingTimeouts.responseHeaderTimeout: "3600s"`
- `ingress.traefik.serversTransport.spec.forwardingTimeouts.idleConnTimeout: "3600s"`

### 2.3 Ingress path default changed

- Removed key: `ingress.path`
- Default ingress path in template changed to:
  - `default (include "seleniumGrid.url.subPath" $) "/"`
- `seleniumGrid.url.subPath` resolves from component subPath config:
  - when `isolateComponents=true`: `components.router.subPath`
  - when `isolateComponents=false`: `hub.subPath`

This makes path default follow Grid sub-path behavior.

### 2.4 Sub-chart values renamed

Removed block:

- `ingress-nginx: ...`

Added block:

- `traefik.ingressClass.enabled`
- `traefik.ingressClass.isDefaultClass`
- `traefik.ingressClass.name`
- `traefik.tlsStore.default.defaultCertificate.secretName` (optional)

## 3. Template behavior changes

### 3.1 Ingress annotations

In `_helpers.tpl` and `ingress.yaml`:

- Removed helper: `seleniumGrid.ingress.nginx.annotations.default`
- Added helper: `seleniumGrid.ingress.traefik.annotations.default`
- Ingress now builds default annotations from `ingress.traefik` (when class is `traefik`)

### 3.2 Backend Service annotations

Added helper:

- `seleniumGrid.service.traefik.annotations.default`

This applies on Hub/Router Service:

- `traefik.ingress.kubernetes.io/service.serversscheme`
- `traefik.ingress.kubernetes.io/service.serverstransport`

### 3.3 New ServersTransport resource

New template:

- `templates/traefik-servers-transport.yaml`

Resource created when:

- ingress enabled
- Traefik annotations enabled
- `ingress.traefik.serversTransport.enabled=true`

Resource name helpers added in `_nameHelpers.tpl`:

- `seleniumGrid.ingress.traefik.serversTransport.name`
- `seleniumGrid.ingress.traefik.serversTransport.ref`

## 4. Key migration mapping (old -> new)

- Controller dependency:
  - `ingress-nginx` -> `traefik`
- Ingress class:
  - `ingress.className: nginx` -> `ingress.className: traefik`
- Controller values root:
  - `ingress-nginx.*` -> `traefik.*`
- Default cert:
  - `ingress-nginx.controller.extraArgs.default-ssl-certificate` -> `traefik.tlsStore.default.defaultCertificate.secretName`
- HTTP/2 toggle semantics:
  - `ingress.nginx.useHttp2=true/false` -> `ingress.traefik.serversTransport.spec.disableHTTP2=false/true`
- Proxy/read/write timeouts:
  - `ingress.nginx.proxyTimeout` -> `ingress.traefik.serversTransport.spec.forwardingTimeouts.*`
- SSL passthrough / proxy SSL secret model:
  - NGINX annotation model removed
  - Traefik backend transport model via `ServersTransport` + `service.serverstransport`

## 5. README / generated config docs updates

Updated docs:

- `README.md`
  - section renamed to `Configuration of Traefik Ingress Controller`
  - annotation mapping changed to Traefik keys
  - secure-ingress examples now use `traefik.tlsStore.default.defaultCertificate.secretName`
- `CONFIGURATION.md`
  - removed `ingress.nginx.*`
  - added `ingress.traefik.*`
  - dependency config changed from `ingress-nginx` to `traefik`

## 6. Test and reference values updates

Updated ref values and CI/template fixtures to Traefik:

- `tests/charts/refValues/simplex-docker-desktop.yaml`
- `tests/charts/refValues/simplex-minikube.yaml`
- `tests/charts/refValues/sample-aws.yaml`
- `tests/charts/ci/base-auth-ingress-values.yaml`
- `tests/charts/ci/base-subPath-values.yaml`
- `tests/charts/templates/render/dummy.yaml`
- `tests/charts/templates/render/dummy_solution.yaml`
- `tests/charts/templates/test.py`

Common migration examples in those files:

- `className: traefik`
- Traefik router annotations or `ingress.traefik.*` values
- `traefik` sub-chart config for hostPort/service/deployment

## 7. Other config changes included in the same commit

Also changed in this commit (not strictly ingress-controller replacement, but relevant to behavior):

- Jaeger tracing endpoint defaults:
  - `tracing.exporterEndpoint` changed from `{{ .Release.Name }}-jaeger-collector:4317` to `{{ .Release.Name }}-jaeger:4317`
  - tracing ingress backend service changed from `{{ .Release.Name }}-jaeger-query` to `{{ .Release.Name }}-jaeger`
- Jaeger sub-chart values structure simplified under `jaeger.jaeger.extraEnv`
