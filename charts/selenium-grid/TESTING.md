# Testing Selenium Grid Helm Chart

All related testing to this helm chart will be documented in this file.

## Test Traceability Matrix

| Features               | TC Description                                                       | Coverage |
|------------------------|----------------------------------------------------------------------|----------|
| Basic Auth             | Basic Auth is disabled                                               | &check;  |
|                        | Basic Auth is enabled                                                | &cross;  |
| Auto scaling           | Auto scaling with `enableWithExistingKEDA` is `true`                 | &check;  |
|                        | Auto scaling with `scalingType` is `job`                             | &check;  |
|                        | Auto scaling with `scalingType` is `deployment`                      | &cross;  |
|                        | Auto scaling with `autoscaling.scaledOptions.minReplicaCount` is `0` | &check;  |
| Ingress                | Ingress is enabled without `hostname`                                | &check;  |
|                        | Hub `sub-path` is set with Ingress `ImplementationSpecific` paths    | &check;  |
| Distributed components | `isolateComponents` is enabled                                       | &check;  |
| Browser Nodes          | Node `nameOverride` is set                                           | &check;  |
|                        | Sanity tests in node                                                 | &check;  |
|                        | Video recorder is enabled in node                                    | &cross;  |

## Build & test Docker images with Helm charts
Noted: These `make` commands are composed and tested on Linux x86_64.
Run entire commands to build and test Docker images with Helm charts in local environment.

```bash
# Back to root directory
cd ../..

# Build Docker images
make build

# Setup Kubernetes environment
make chart_setup_env

# Setup Kubernetes cluster
make chart_cluster_setup

# Test Selenium Grid on Kubernetes
make chart_test

# Cleanup Kubernetes cluster
make chart_cluster_cleanup
```
