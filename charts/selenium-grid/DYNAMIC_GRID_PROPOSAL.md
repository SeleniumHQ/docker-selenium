# Dynamic Grid Helm Integration Proposal

## Context

Today the Helm chart models two node patterns:

- Fixed browser node Deployments via `chromeNode`, `firefoxNode`, `edgeNode`, `relayNode`
- KEDA-driven autoscaling via `autoscaling.*` plus `crossBrowsers.*[].hpa`

The repository now also contains a Kubernetes Dynamic Grid sample under [kubernetes/DynamicGrid](../../kubernetes/DynamicGrid), based on `selenium/node-kubernetes` and a `kubernetes.toml` file per Dynamic Grid controller.

The chart does not yet expose that model.

## Goals

- Add Dynamic Grid support to `charts/selenium-grid` without breaking existing chart users.
- Keep the current `autoscaling.*` tree dedicated to KEDA-based Grid scaler behavior.
- Allow users to define multiple Dynamic Node pools.
- Allow each Dynamic Node pool to have its own `kubernetes.toml`.
- Keep the chart flexible enough for:
  - simple inline image-to-capabilities mappings
  - advanced `configmap:` job-template mode from `NodeKubernetes/config.toml`
  - custom pod scheduling, resources, and environment per Dynamic Node pool
- Reuse existing chart primitives where possible: labels, secrets, event-bus wiring, logging, tracing, TLS, ingress, and basic auth.

## Non-Goals

- Do not retrofit Dynamic Grid into the existing `autoscaling.*` values tree.
- Do not remove KEDA support.
- Do not auto-convert `crossBrowsers` entries into Dynamic Grid TOML.
- Do not require users to abandon static nodes; hybrid static + dynamic should remain possible.
- Initial implementation does not need to support `selenium/standalone-kubernetes`.
  Phase 1 should focus on Dynamic Node pools using `selenium/node-kubernetes`.

## High-Level Design

Introduce a new top-level values section:

```yaml
dynamicGrid:
  enabled: false
```

When `dynamicGrid.enabled=true`, the chart renders one or more `selenium/node-kubernetes` Deployments, each backed by its own ConfigMap containing `kubernetes.toml`.

Each Dynamic Node pool acts as a controller that creates browser Jobs on demand, so KEDA resources are not part of this mode.

## Compatibility Rules

### Backward Compatibility

- `autoscaling.*` remains unchanged and continues to mean KEDA only.
- Existing releases that do not set `dynamicGrid.enabled=true` behave exactly as they do today.

### Coexistence

- `dynamicGrid.enabled=true` should be allowed together with fixed-size browser nodes (`chromeNode`, `firefoxNode`, `edgeNode`, `relayNode`).
- `dynamicGrid.enabled=true` should be rejected when either of these is enabled:
  - `autoscaling.enabled=true`
  - `autoscaling.enableWithExistingKEDA=true`

Reason: both KEDA autoscaling and Dynamic Grid solve elastic capacity, but with different control planes and values models.

## Proposed Values API

### Top-Level Structure

```yaml
dynamicGrid:
  enabled: false

  serviceAccount:
    create: true
    nameOverride: ""
    annotations: {}

  rbac:
    create: true
    role:
      nameOverride: ""
      annotations: {}
      rules:
        - apiGroups: ["batch"]
          resources: ["jobs"]
          verbs: ["create", "delete", "get", "list", "watch"]
        - apiGroups: [""]
          resources: ["pods"]
          verbs: ["get", "list", "watch"]
        - apiGroups: [""]
          resources: ["pods/log"]
          verbs: ["get"]
    roleBinding:
      nameOverride: ""
      annotations: {}

  assets:
    enabled: true
    existingClaim: ""
    nameOverride: ""
    accessModes: ["ReadWriteMany"]
    size: 5Gi
    storageClassName: ""
    annotations: {}

  defaults:
    imageRegistry: ""
    imageName: node-kubernetes
    imageTag: ""
    imagePullPolicy: IfNotPresent
    imagePullSecret: ""
    replicas: 1
    resources: {}
    nodeSelector: {}
    tolerations: []
    affinity: {}
    topologySpreadConstraints: []
    priorityClassName: ""
    annotations: {}
    labels: {}
    extraEnvironmentVariables: []
    extraEnvFrom: []
    extraVolumes: []
    extraVolumeMounts: []
    terminationGracePeriodSeconds: 300
    startupProbe: {}
    readinessProbe: {}
    livenessProbe: {}
    env:
      dynamicMaxSessions: ""
      dynamicOverrideMaxSessions: ""
      nodeSessionTimeout: ""
      nodeHeartbeatPeriod: ""
      nodeConnectionLimitPerSession: ""
      nodeEnableManagedDownloads: true
      externalUrl: ""
    config:
      fileName: kubernetes.toml
      rawToml: ""
      kubernetes:
        namespace: ""
        serviceAccount: ""
        imagePullPolicy: ""
        serverStartTimeout: ""
        terminationGracePeriod: ""
        labelInheritPrefix: ""
        assetsPath: /opt/selenium/assets
        videoImage: ""
        configs: []
        extraToml: ""
    service:
      enabled: false
      type: ClusterIP
      annotations: {}
      externalTrafficPolicy: ""
      sessionAffinity: ""
      port: 5555

  jobTemplates: {}

  nodes: []
```

## Dynamic Node Pool Schema

Each entry in `dynamicGrid.nodes` should inherit from `dynamicGrid.defaults`.

```yaml
dynamicGrid:
  nodes:
    - name: linux-general
      enabled: true
      replicas: 1
      imageTag: 4.42.0-20260303
      env:
        dynamicMaxSessions: "10"
        dynamicOverrideMaxSessions: "true"
        nodeSessionTimeout: "600"
      config:
        kubernetes:
          configs:
            - image: selenium/standalone-chromium:4.42.0-20260303
              capabilities:
                browserName: chrome
                platformName: linux
            - image: selenium/standalone-firefox:4.42.0-20260303
              capabilities:
                browserName: firefox
                platformName: linux
```

### Required Fields

- `name`
  Used in resource names and labels.

### Common Pool Overrides

- `enabled`
- `replicas`
- `imageRegistry`
- `imageName`
- `imageTag`
- `imagePullPolicy`
- `imagePullSecret`
- `resources`
- `nodeSelector`
- `tolerations`
- `affinity`
- `topologySpreadConstraints`
- `priorityClassName`
- `annotations`
- `labels`
- `extraEnvironmentVariables`
- `extraEnvFrom`
- `extraVolumes`
- `extraVolumeMounts`
- `terminationGracePeriodSeconds`
- `startupProbe`
- `readinessProbe`
- `livenessProbe`
- `service`
- `assets.existingClaim`

## TOML Specification

Each Dynamic Node pool gets its own ConfigMap with a single key:

- `kubernetes.toml`

### Config Authoring Modes

Support both authoring modes below.

#### 1. Structured Mode

Use YAML and let Helm render TOML:

```yaml
config:
  kubernetes:
    assetsPath: /opt/selenium/assets
    terminationGracePeriod: 60
    labelInheritPrefix: "se/"
    configs:
      - image: selenium/standalone-chromium:4.42.0-20260303
        capabilities:
          browserName: chrome
          platformName: linux
      - image: selenium/standalone-firefox:4.42.0-20260303
        capabilities:
          browserName: firefox
          platformName: linux
```

Rendered TOML:

```toml
[kubernetes]
configs = [
  "selenium/standalone-chromium:4.42.0-20260303", "{\"browserName\":\"chrome\",\"platformName\":\"linux\"}",
  "selenium/standalone-firefox:4.42.0-20260303", "{\"browserName\":\"firefox\",\"platformName\":\"linux\"}"
]
assets-path = "/opt/selenium/assets"
termination-grace-period = 60
label-inherit-prefix = "se/"
```

#### 2. Raw Mode

Allow full TOML passthrough for advanced use cases:

```yaml
config:
  rawToml: |
    [kubernetes]
    configs = [
      "selenium/standalone-chromium:4.42.0-20260303", '{"browserName":"chrome","platformName":"linux"}'
    ]
    assets-path = "/opt/selenium/assets"
```

### Precedence

- `config.rawToml` wins over structured fields.
- `config.kubernetes.extraToml` is appended last in structured mode only.

This keeps the common path easy while preserving a full escape hatch.

## Browser Job Template Support

Dynamic Grid already supports `configmap:<name>` entries in `kubernetes.toml`.
The chart should expose this cleanly.

### Proposed Values

```yaml
dynamicGrid:
  jobTemplates:
    firefox-job-template: |
      apiVersion: batch/v1
      kind: Job
      metadata:
        labels:
          se/job-type: browser
      spec:
        template:
          spec:
            containers:
              - name: browser
                image: selenium/standalone-firefox:4.42.0-20260303
```

Then inside a pool:

```yaml
config:
  kubernetes:
    configs:
      - templateConfigMap: firefox-job-template
        capabilities:
          browserName: firefox
          platformName: linux
```

### Render Rule

The chart renders one ConfigMap per entry in `dynamicGrid.jobTemplates` with key `template`.
The TOML renderer converts `templateConfigMap: firefox-job-template` into:

```toml
"configmap:firefox-job-template", "{\"browserName\":\"firefox\",\"platformName\":\"linux\"}"
```

If cross-namespace references are needed, allow:

- `templateConfigMapNamespace`

Which renders as:

```toml
"configmap:other-namespace/firefox-job-template", "{...}"
```

## Rendered Kubernetes Resources

When `dynamicGrid.enabled=true`, the chart should render:

- One ServiceAccount for Dynamic Grid controllers, unless `create=false`
- One Role and one RoleBinding for Dynamic Grid controllers, unless `create=false`
- One PVC for shared assets unless `assets.existingClaim` is set
- One ConfigMap per Dynamic Node pool containing `kubernetes.toml`
- One Deployment per Dynamic Node pool using `selenium/node-kubernetes`
- Optional Service per Dynamic Node pool
- Optional ConfigMaps for `dynamicGrid.jobTemplates`

### Naming

Recommended names:

- ServiceAccount: `<release>-selenium-dynamic-grid`
- Role: `<release>-selenium-dynamic-grid`
- RoleBinding: `<release>-selenium-dynamic-grid`
- Assets PVC: `<release>-selenium-dynamic-assets`
- Pool ConfigMap: `<release>-selenium-dynamic-node-<pool>-config`
- Pool Deployment: `<release>-selenium-dynamic-node-<pool>`
- Pool Service: `<release>-selenium-dynamic-node-<pool>`

## Integration with Existing Chart Components

Dynamic Node Deployments should reuse existing chart resources where appropriate:

- Event bus host and ports from `event-bus-configmap.yaml`
- Grid URL / ingress / subPath from existing URL helpers and `SE_NODE_GRID_URL`
- Registration secret from existing secrets
- Logging and tracing config from existing logging/server ConfigMaps
- TLS and basic auth secrets where enabled

This gives Dynamic Grid parity with the current chart’s operational model.

## Pod Template Approach

Do not force Dynamic Grid controllers into the existing browser-node pod helper.

Reason:

- `selenium/node-kubernetes` has different probes, mounts, ports, and semantics from `node-chrome`, `node-firefox`, `node-edge`, and `relay`
- Its primary config input is `kubernetes.toml`, not stereotype env vars or KEDA trigger metadata

Recommendation:

- Add a dedicated helper such as `seleniumGrid.dynamicNode.podTemplate`
- Reuse small common helpers only for:
  - image resolution
  - labels
  - annotations
  - envFrom wiring
  - imagePullSecrets

## Validation Rules

The chart should fail template rendering when:

- `dynamicGrid.enabled=true` and `autoscaling.enabled=true`
- `dynamicGrid.enabled=true` and `autoscaling.enableWithExistingKEDA=true`
- a pool has both `config.rawToml` and invalid structured config
- a `configs[]` item sets both `image` and `templateConfigMap`
- a `configs[]` item sets neither `image` nor `templateConfigMap`
- two pools use the same `name`

## Example Values

```yaml
isolateComponents: true

dynamicGrid:
  enabled: true

  assets:
    existingClaim: selenium-assets

  defaults:
    imageTag: 4.42.0-20260303
    resources:
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "1"
        memory: "2Gi"
    env:
      dynamicMaxSessions: "10"
      dynamicOverrideMaxSessions: "true"
      nodeSessionTimeout: "600"
    config:
      kubernetes:
        assetsPath: /opt/selenium/assets
        terminationGracePeriod: 60

  jobTemplates:
    chrome-dev-template: |
      apiVersion: batch/v1
      kind: Job
      spec:
        template:
          spec:
            containers:
              - name: browser
                image: selenium/standalone-chrome:dev

  nodes:
    - name: linux-stable
      replicas: 1
      config:
        kubernetes:
          configs:
            - image: selenium/standalone-chromium:4.42.0-20260303
              capabilities:
                browserName: chrome
                platformName: linux
            - image: selenium/standalone-firefox:4.42.0-20260303
              capabilities:
                browserName: firefox
                platformName: linux

    - name: chrome-dev
      nodeSelector:
        workload-type: browser
      config:
        kubernetes:
          configs:
            - templateConfigMap: chrome-dev-template
              capabilities:
                browserName: chrome
                browserVersion: dev
                platformName: linux
```

## Migration Story

### Existing KEDA Users

No change unless they opt in to `dynamicGrid.enabled=true`.

### Users Moving from KEDA to Dynamic Grid

- disable `autoscaling.enabled`
- disable `autoscaling.enableWithExistingKEDA`
- disable autoscaled `crossBrowsers` entries if they are no longer needed
- define one or more `dynamicGrid.nodes`

### Users Moving from `kubernetes/DynamicGrid`

The chart should cover the sample’s three resource groups:

- BaseConfig
  - ConfigMap -> per-pool ConfigMaps instead of one shared ConfigMap
  - PVC -> `dynamicGrid.assets`
  - ServiceAccount/Role/RoleBinding -> `dynamicGrid.serviceAccount` and `dynamicGrid.rbac`
- Hub_Node
  - Hub remains chart-managed as today
  - Node Kubernetes becomes `dynamicGrid.nodes[]`

## Implementation Plan

### Phase 1

- Add values schema and validation
- Add Dynamic Grid ServiceAccount / Role / RoleBinding / PVC templates
- Add per-pool ConfigMap and Deployment templates
- Reuse existing event-bus, logging, server, secrets, TLS, and URL helpers
- Add examples and docs

### Phase 2

- Add inline chart-managed job-template ConfigMaps
- Add optional per-pool Service
- Add chart tests for:
  - one pool
  - multiple pools
  - raw TOML mode
  - templateConfigMap mode
  - rejection when KEDA and Dynamic Grid are both enabled

### Optional Future Phase

- Add `standalone-kubernetes` chart support as a separate mode if there is demand

## Recommendation

Use a new top-level `dynamicGrid` tree instead of overloading `autoscaling`.

This is the cleanest path because:

- it preserves backward compatibility
- it keeps KEDA and Dynamic Grid conceptually separate
- it allows multiple Dynamic Node pools with distinct TOML files
- it leaves room for advanced `configmap:` job templates without distorting the current browser-node schema
- it supports a hybrid rollout where teams can keep fixed browser nodes while introducing Dynamic Grid gradually
