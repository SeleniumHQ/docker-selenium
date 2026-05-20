# Selenium Grid Grafana Dashboards

Pre-built Grafana dashboards for monitoring Selenium Grid via the [Prometheus exporter](../exporter/README.md).

## Dashboards

| File | UID | Purpose |
|---|---|---|
| `selenium-grid-overview.json` | `sel-grid-overview` | Grid health at a glance: slots, sessions, queue, node summary table |
| `selenium-node-health.json` | `sel-node-health` | Per-node status, capacity, stereotype breakdown, status duration trend |
| `selenium-sessions.json` | `sel-sessions` | Active sessions by browser/platform, per-session table with test & container name, completed session history |
| `selenium-queue-capacity.json` | `sel-queue-cap` | Queue depth, slot utilization pressure, queue breakdown by desired capability |
| `selenium-cross-browser.json` | `sel-cross-browser` | Cross-browser testing coverage: active counts, slot utilization, session trends, queue pressure, and version breakdown per browser |

All dashboards auto-refresh every 30 s (Queue & Capacity: 15 s).

## Datasource requirement

Dashboards reference the Prometheus datasource by UID `prometheus`. This is the default UID in both kube-prometheus-stack and standard Grafana Docker Compose setups. If your datasource uses a different UID, update it in Grafana under **Connections → Data sources**.

## Provisioning

### Docker Compose

Mount the dashboards directory into Grafana's provisioning path and add a provisioning config:

```yaml
grafana:
  volumes:
    - ./.monitoring/dashboards:/var/lib/grafana/dashboards/selenium
    - ./.monitoring/config/grafana/provisioning:/etc/grafana/provisioning
```

`provisioning/dashboards/selenium.yaml`:

```yaml
apiVersion: 1
providers:
  - name: Selenium Grid
    folder: Selenium Grid
    type: file
    options:
      path: /var/lib/grafana/dashboards/selenium
```

### Kubernetes (Helm chart)

When `monitoring.enabled: true` is set, the Helm chart automatically creates a ConfigMap per dashboard labelled `grafana_dashboard: "1"`. Grafana's sidecar container detects these labels and provisions the dashboards into the **Selenium Grid** folder.

```yaml
monitoring:
  enabled: true
  grafana:
    dashboards:
      enabled: true  # default when monitoring.enabled=true
```

The Grafana sidecar must be configured to watch all namespaces (kube-prometheus-stack default):

```yaml
kube-prometheus-stack:
  grafana:
    sidecar:
      dashboards:
        searchNamespace: ALL
```

## Updating dashboards

1. Edit the dashboard in the Grafana UI.
2. Export via **Share → Export → Save to file** (enable *Export for sharing externally* to include `__inputs`).
3. Replace the file in this directory.
4. If the datasource input was exported as `${DS_PROMETHEUS}`, replace every occurrence with the literal string `prometheus` and remove the `__inputs` and `__requires` blocks — provisioning does not process `__inputs`, only the UI importer does.
5. Run `make copy_dashboards` to sync the updated files into the Helm chart.
