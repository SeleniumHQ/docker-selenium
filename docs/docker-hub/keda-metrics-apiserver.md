---
description: Image with stable KEDA core version and patch implementation for Selenium Grid Scaler in Kubernetes
---
# Introduction

Selenium Grid Scaler is a built-in scaler is maintained in upstream KEDA [repository](https://github.com/kedacore/keda). The scaler implementation could be found [here](https://github.com/kedacore/keda/blob/main/pkg/scalers/selenium_grid_scaler.go). The official docs of the scaler could be seen [here](https://keda.sh/docs/latest/scalers/selenium-grid-scaler/).

Now, [SeleniumHQ/docker-selenium](https://github.com/SeleniumHQ/docker-selenium) involves as the maintainer for the scaler.

In order to deliver and get feedback continuously on any new bug fixes, improvement, or features for the Selenium Grid scaler. We select the latest stable version of KEDA core, patch the scaler implementation then build and deploy KEDA container images following our image tag convention.

The stable implementation will be merged to the upstream KEDA repository frequently and will be available in the next KEDA core release.

# How to use the patched scaler

Replace the image registry and tag of these KEDA components with the patched image tag:

```bash
docker pull selenium/keda:2.20.1-20260909
docker pull selenium/keda-metrics-apiserver:2.20.1-20260909
docker pull selenium/keda-admission-webhooks:2.20.1-20260909
```

Besides that, you also can use image tag `latest` or `nightly`.

If you are deploying KEDA core using their official Helm [chart](https://github.com/kedacore/charts), you can overwrite the image registry and tag by providing the following values in the `values.yaml` file. For example:

```yaml
  image:
    keda:
      registry: selenium
      repository: keda
      tag: "2.20.1-20260909"
    metricsApiServer:
      registry: selenium
      repository: keda-metrics-apiserver
      tag: "2.20.1-20260909"
    webhooks:
      registry: selenium
      repository: keda-admission-webhooks
      tag: "2.20.1-20260909"
```

If you are deployment Selenium Grid chart with `autoscaling.enabled` is `true` (implies installing KEDA sub-chart), KEDA images registry and tag already set in the `values.yaml`. Refer to list [configuration](https://github.com/SeleniumHQ/docker-selenium/blob/trunk/charts/selenium-grid/CONFIGURATION.md).
