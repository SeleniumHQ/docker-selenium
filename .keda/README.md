# Introduction

Selenium Grid Scaler is a built-in scaler is maintained in upstream KEDA [repository](https://github.com/kedacore/keda). The scaler implementation could be found [here](https://github.com/kedacore/keda/blob/main/pkg/scalers/selenium_grid_scaler.go). The official docs of the scaler could be seen [here](https://keda.sh/docs/latest/scalers/selenium-grid-scaler/).

Now, [SeleniumHQ/docker-selenium](https://github.com/SeleniumHQ/docker-selenium) involves as the maintainer for the scaler.

In order to deliver and get feedback continuously on any new bug fixes, improvement, or features for the Selenium Grid scaler. We select the latest stable version of KEDA core, patch the scaler implementation then build and deploy KEDA container images following our image tag convention.

The stable implementation will be merged to the upstream KEDA repository frequently and will be available in the next KEDA core release.

# How to use the patched scaler

Replace the image registry and tag of these KEDA components with the patched image tag:

```bash
docker pull selenium/keda:2.17.1-selenium-grid-20250606
docker pull selenium/keda-metrics-apiserver:2.17.1-selenium-grid-20250606
docker pull selenium/keda-admission-webhooks:2.17.1-selenium-grid-20250606
```

Besides that, you also can use image tag `latest` or `nightly`.

If you are deploying KEDA core using their official Helm [chart](https://github.com/kedacore/charts), you can overwrite the image registry and tag by providing the following values in the `values.yaml` file. For example:

```yaml
  image:
    keda:
      registry: selenium
      repository: keda
      tag: "2.17.1-selenium-grid-20250606"
    metricsApiServer:
      registry: selenium
      repository: keda-metrics-apiserver
      tag: "2.17.1-selenium-grid-20250606"
    webhooks:
      registry: selenium
      repository: keda-admission-webhooks
      tag: "2.17.1-selenium-grid-20250606"
```

If you are deployment Selenium Grid chart with `autoscaling.enabled` is `true` (implies installing KEDA sub-chart), KEDA images registry and tag already set in the `values.yaml`. Refer to list [configuration](../charts/selenium-grid/CONFIGURATION.md).

If you want to disable default patched KEDA image tags in Selenium Grid chart, you can set via Helm CLI `--set keda.image=null` or the same in values file.

# Pull requests under testing

Here is list of pull requests that are under testing and will be merged to the upstream KEDA repository.
You can involve to review and discuss the pull requests to help us early detect and fix any issues.

[kedacore/keda](https://github.com/kedacore/keda)

- ~~https://github.com/kedacore/keda/pull/6772 (merged, v2.17.1)~~

- ~~https://github.com/kedacore/keda/pull/6684 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda/pull/6570 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda/pull/6536 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda/pull/6477 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda/pull/6437 (merged, v2.16.1)~~

- ~~https://github.com/kedacore/keda/pull/6368 (merged, v2.16.1)~~

- ~~https://github.com/kedacore/keda/pull/6169 (merged, v2.16.0)~~

[kedacore/keda-docs](https://github.com/kedacore/keda-docs)

- ~~https://github.com/kedacore/keda-docs/pull/1560 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda-docs/pull/1542 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda-docs/pull/1533 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda-docs/pull/1522 (merged, v2.17.0)~~

- ~~https://github.com/kedacore/keda-docs/pull/1515 (merged, v2.16.1)~~

- ~~https://github.com/kedacore/keda-docs/pull/1468 (merged, v2.16.0)~~

# Test results of the patch scaler

There are tests for the patched scaler implementation. You can run the tests by following the steps in [../tests/README.md](../tests/README.md).

Test results could be referred to

- [results_test_k8s_autoscaling_job_count_strategy_default.md](./results_test_k8s_autoscaling_job_count_strategy_default.md)
- [results_test_k8s_autoscaling_job_count_strategy_default_in_chaos.md](./results_test_k8s_autoscaling_job_count_strategy_default_in_chaos.md)
- [results_test_k8s_autoscaling_job_count_strategy_default_with_node_max_sessions.md](./results_test_k8s_autoscaling_job_count_strategy_default_with_node_max_sessions.md)
- [results_test_k8s_autoscaling_deployment_count.md](./results_test_k8s_autoscaling_deployment_count.md)
- [results_test_k8s_autoscaling_deployment_count_in_chaos.md](./results_test_k8s_autoscaling_deployment_count_in_chaos.md)
- [results_test_k8s_autoscaling_deployment_count_with_node_max_sessions.md](./results_test_k8s_autoscaling_deployment_count_with_node_max_sessions.md)

# Resources

You can inspect the implementation of current Selenium Grid scaler:

- [selenium_grid_scaler.go](./scalers/selenium_grid_scaler.go)
- [selenium_grid_scaler_test.go](./scalers/selenium_grid_scaler_test.go)
- [selenium-grid-scaler.md](./scalers/selenium-grid-scaler.md)
