# Dynamic Grid Helm Integration Proposal

## Context

The chart already models browser nodes with `chromeNode`, `firefoxNode`, `edgeNode`, and their additional `crossBrowsers` entries. Dynamic Grid should reuse that model instead of introducing a parallel browser-pool values schema.

## Design

When `dynamicGrid.enabled=true`, the chart renders `selenium/node-kubernetes` controller Deployments for enabled browser node entries:

- `chromeNode` and `crossBrowsers.chromeNode`
- `firefoxNode` and `crossBrowsers.firefoxNode`
- `edgeNode` and `crossBrowsers.edgeNode`

KEDA autoscaling remains a separate mode. The chart rejects `dynamicGrid.enabled=true` when `autoscaling.enabled=true` or `autoscaling.enableWithExistingKEDA=true`.

## Browser Node Reuse

Dynamic Grid uses the same merge behavior as the existing node templates:

```gotemplate
{{ $nodeConfig := merge $newNode $.Values.chromeNode }}
```

The merged node config drives the controller Deployment metadata, replica count, scheduling fields, resources, extra env, extra volumes, service, image pull secret, and lifecycle-related settings.

The browser Job image in `kubernetes.toml` is derived from the existing node image settings:

- registry: node-specific `imageRegistry`, falling back to `global.seleniumGrid.imageRegistry`
- tag: node-specific `imageTag`, falling back to `global.seleniumGrid.nodesImageTag`
- image name: default `node-*` names are converted to `standalone-*`

## Capabilities

Capabilities in `kubernetes.toml` are generated from each node's `hpa` map:

- include non-empty keys from `hpa`
- exclude `unsafeSsl`
- merge `nodeCustomCapabilities` into the generated capabilities

`nodeCustomCapabilities` may be provided as a map or as the existing string form used by static nodes.

## Max Sessions

`nodeMaxSessions` drives the Dynamic Grid controller env:

```yaml
- name: SE_DYNAMIC_MAX_SESSIONS
  value: "<nodeMaxSessions>"
```

When `nodeMaxSessions` is greater than `1`, the chart also sets:

```yaml
- name: SE_DYNAMIC_OVERRIDE_MAX_SESSIONS
  value: "true"
```

## Remaining Dynamic Grid Values

The `dynamicGrid` tree is limited to Dynamic Grid infrastructure and controller-wide settings:

- service account and RBAC
- shared assets PVC
- controller image override
- node-kubernetes TOML global fields such as namespace, service account, assets path, termination grace period, and extra TOML
