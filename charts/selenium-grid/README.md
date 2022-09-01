# Selenium-Grid Helm Chart

This chart enables the creation of a Selenium Grid Server in Kubernetes.

## Installing the chart

If you want to install the latest master version of Selenium Grid onto your cluster you can do that by using the helm charts repository located at https://www.selenium.dev/docker-selenium.

```bash
# Add docker-selenium helm repository
helm repo add docker-selenium https://www.selenium.dev/docker-selenium

# Update charts from docker-selenium repo
helm repo update

# List all versions present in the docker-selenium repo
helm search repo docker-selenium --versions

# Install basic grid latest version
helm install selenium-grid docker-selenium/selenium-grid

# Or install full grid (Router, Distributor, EventBus, SessionMap and SessionQueue components separated)
helm install selenium-grid docker-selenium/selenium-grid --set isolateComponents=true

# Or install specified version
helm install selenium-grid docker-selenium/selenium-grid --version <version>

# In both cases grid exposed by default using ingress. You may want to set hostname for the grid. Default hostname is selenium-grid.local.
helm install selenium-grid --set ingress.hostname=selenium-grid.k8s.local docker-selenium/chart/selenium-grid/.
```

## Updating Selenium-Grid release

Once you have a new chart version, you can update your selenium-grid running:

```bash
helm upgrade selenium-grid docker-selenium/selenium-grid
```

## Uninstalling Selenium Grid release

To uninstall:

```bash
helm uninstall selenium-grid
```

## Configuration

For now, global configuration supported is:

| Parameter                             | Default                            | Description                           |
| -----------------------------------   | ---------------------------------- | ------------------------------------- |
| `global.seleniumGrid.imageTag`        | `4.4.0-20220831`                   | Image tag for all selenium components |
| `global.seleniumGrid.nodesImageTag`   | `4.4.0-20220831`                   | Image tag for browser's nodes         |
| `global.seleniumGrid.imagePullSecret` | `""`                               | Pull secret to be used for all images |

This table contains the configuration parameters of the chart and their default values:

| Parameter                               | Default                            | Description                                                                                                                |
| --------------------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `isolateComponents`                     | `false`                            | Deploy Router, Distributor, EventBus, SessionMap and Nodes separately                                                      |
| `busConfigMap.name`                     | `selenium-event-bus-config`        | Name of the configmap that contains SE_EVENT_BUS_HOST, SE_EVENT_BUS_PUBLISH_PORT and SE_EVENT_BUS_SUBSCRIBE_PORT variables |
| `ingress.enabled`                       | `true`                             | Enable or disable ingress resource                                                                                         |
| `ingress.className`                     | `""`                               | Name of ingress class to select which controller will implement ingress resource                                           |
| `ingress.annotations`                   | `{}`                               | Custom annotations for ingress resource                                                                                    |
| `ingress.hostname`                      | `selenium-grid.local`              | Default host for the ingress resource                                                                                      |
| `ingress.tls`                           | `[]`                               | TLS backend configuration for ingress resource                                                                             |
| `busConfigMap.annotations`              | `{}`                               | Custom annotations for configmap                                                                                           |
| `chromeNode.enabled`                    | `true`                             | Enable chrome nodes                                                                                                        |
| `chromeNode.replicas`                   | `1`                                | Number of chrome nodes                                                                                                     |
| `chromeNode.imageName`                  | `selenium/node-chrome`             | Image of chrome nodes                                                                                                      |
| `chromeNode.imageTag`                   | `4.4.0-20220831`                   | Image of chrome nodes                                                                                                      |
| `chromeNode.imagePullPolicy`            | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `chromeNode.imagePullSecret`            | `""`                               | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)               |
| `chromeNode.ports`                      | `[5555]`                           | Port list to enable on container                                                                                           |
| `chromeNode.seleniumPort`               | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `chromeNode.seleniumServicePort`        | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `chromeNode.annotations`                | `{}`                               | Annotations for chrome-node pods                                                                                           |
| `chromeNode.labels`                     | `{}`                               | Labels for chrome-node pods                                                                                                |
| `chromeNode.resources`                  | `See values.yaml`                  | Resources for chrome-node pods                                                                                             |
| `chromeNode.tolerations`                | `[]`                               | Tolerations for chrome-node pods                                                                                           |
| `chromeNode.nodeSelector`               | `{}`                               | Node Selector for chrome-node pods                                                                                         |
| `chromeNode.hostAliases`                | `nil`                              | Custom host aliases for chrome nodes                                                                                       |
| `chromeNode.priorityClassName`          | `""`                               | Priority class name for chrome-node pods                                                                                   |
| `chromeNode.extraEnvironmentVariables`  | `nil`                              | Custom environment variables for chrome nodes                                                                              |
| `chromeNode.extraEnvFrom`               | `nil`                              | Custom environment taken from `configMap` or `secret` variables for chrome nodes                                           |
| `chromeNode.service.enabled`            | `true`                             | Create a service for node                                                                                                  |
| `chromeNode.service.type`               | `ClusterIP`                        | Service type                                                                                                               |
| `chromeNode.service.annotations`        | `{}`                               | Custom annotations for service                                                                                             |
| `chromeNode.dshmVolumeSizeLimit`        | `1Gi`                              | Size limit for DSH volume mounted in container (if not set, default is "1Gi")                                              |
| `chromeNode.startupProbe`               | `{}`                               | Probe to check pod is started successfully                                                                                 |
| `chromeNode.terminationGracePeriodSeconds` | `30`                            | Time to graceful terminate container (default: 30s)                                                                        |
| `chromeNode.lifecycle`                  | `{}`                               | hooks to make pod correctly shutdown or started                                                                            |
| `chromeNode.extraVolumeMounts`          | `[]`                               | Extra mounts of declared ExtraVolumes into pod                                                                             |
| `chromeNode.extraVolumes`               | `[]`                               | Extra Volumes declarations to be used in the pod (can be any supported volume type: ConfigMap, Secret, PVC, NFS, etc.)     |
| `firefoxNode.enabled`                   | `true`                             | Enable firefox nodes                                                                                                       |
| `firefoxNode.replicas`                  | `1`                                | Number of firefox nodes                                                                                                    |
| `firefoxNode.imageName`                 | `selenium/node-firefox`            | Image of firefox nodes                                                                                                     |
| `firefoxNode.imageTag`                  | `4.4.0-20220831`                   | Image of firefox nodes                                                                                                     |
| `firefoxNode.imagePullPolicy`           | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `firefoxNode.imagePullSecret`           | `""`                               | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)               |
| `firefoxNode.ports`                     | `[5555]`                           | Port list to enable on container                                                                                           |
| `firefoxNode.seleniumPort`              | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `firefoxNode.seleniumServicePort`       | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `firefoxNode.annotations`               | `{}`                               | Annotations for firefox-node pods                                                                                          |
| `firefoxNode.labels`                    | `{}`                               | Labels for firefox-node pods                                                                                               |
| `firefoxNode.resources`                 | `See values.yaml`                  | Resources for firefox-node pods                                                                                            |
| `firefoxNode.tolerations`               | `[]`                               | Tolerations for firefox-node pods                                                                                          |
| `firefoxNode.nodeSelector`              | `{}`                               | Node Selector for firefox-node pods                                                                                        |
| `firefoxNode.hostAliases`               | `nil`                              | Custom host aliases for firefox nodes                                                                                      |
| `firefoxNode.priorityClassName`         | `""`                               | Priority class name for firefox-node pods                                                                                  |
| `firefoxNode.extraEnvironmentVariables` | `nil`                              | Custom environment variables for firefox nodes                                                                             |
| `firefoxNode.extraEnvFrom`              | `nil`                              | Custom environment variables taken from `configMap` or `secret` for firefox nodes                                          |
| `firefoxNode.service.enabled`           | `true`                             | Create a service for node                                                                                                  |
| `firefoxNode.service.type`              | `ClusterIP`                        | Service type                                                                                                               |
| `firefoxNode.service.annotations`       | `{}`                               | Custom annotations for service                                                                                             |
| `firefoxNode.dshmVolumeSizeLimit`       | `1Gi`                              | Size limit for DSH volume mounted in container (if not set, default is "1Gi")                                              |
| `firefoxNode.startupProbe`              | `{}`                               | Probe to check pod is started successfully                                                                                 |
| `firefoxNode.terminationGracePeriodSeconds` | `30`                            | Time to graceful terminate container (default: 30s)                                                                       |
| `firefoxNode.lifecycle`                 | `{}`                               | hooks to make pod correctly shutdown or started                                                                            |
| `firefoxNode.extraVolumeMounts`         | `[]`                               | Extra mounts of declared ExtraVolumes into pod                                                                             |
| `firefoxNode.extraVolumes`              | `[]`                               | Extra Volumes declarations to be used in the pod (can be any supported volume type: ConfigMap, Secret, PVC, NFS, etc.)     |
| `edgeNode.enabled`                      | `true`                             | Enable edge nodes                                                                                                          |
| `edgeNode.replicas`                     | `1`                                | Number of edge nodes                                                                                                       |
| `edgeNode.imageName`                    | `selenium/node-edge`               | Image of edge nodes                                                                                                        |
| `edgeNode.imageTag`                     | `4.4.0-20220831`                   | Image of edge nodes                                                                                                        |
| `edgeNode.imagePullPolicy`              | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `edgeNode.imagePullSecret`              | `""`                               | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)               |
| `edgeNode.ports`                        | `[5555]`                           | Port list to enable on container                                                                                           |
| `edgeNode.seleniumPort`                 | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `edgeNode.seleniumServicePort`          | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `edgeNode.annotations`                  | `{}`                               | Annotations for edge-node pods                                                                                             |
| `edgeNode.labels`                       | `{}`                               | Labels for edge-node pods                                                                                                  |
| `edgeNode.resources`                    | `See values.yaml`                  | Resources for edge-node pods                                                                                               |
| `edgeNode.tolerations`                  | `[]`                               | Tolerations for edge-node pods                                                                                             |
| `edgeNode.nodeSelector`                 | `{}`                               | Node Selector for edge-node pods                                                                                           |
| `edgeNode.hostAliases`                  | `nil`                              | Custom host aliases for edge nodes                                                                                         |
| `edgeNode.priorityClassName`            | `""`                               | Priority class name for edge-node pods                                                                                     |
| `edgeNode.extraEnvironmentVariables`    | `nil`                              | Custom environment variables for firefox nodes                                                                             |
| `edgeNode.extraEnvFrom`                 | `nil`                              | Custom environment taken from `configMap` or `secret` variables for firefox nodes                                          |
| `edgeNode.service.enabled`              | `true`                             | Create a service for node                                                                                                  |
| `edgeNode.service.type`                 | `ClusterIP`                        | Service type                                                                                                               |
| `edgeNode.service.annotations`          | `{}`                               | Custom annotations for service                                                                                             |
| `edgeNode.dshmVolumeSizeLimit`          | `1Gi`                              | Size limit for DSH volume mounted in container (if not set, default is "1Gi")                                              |
| `edgeNode.startupProbe`                 | `{}`                               | Probe to check pod is started successfully                                                                                 |
| `edgeNode.terminationGracePeriodSeconds` | `30`                            | Time to graceful terminate container (default: 30s)                                                                        |
| `edgeNode.lifecycle`                    | `{}`                               | hooks to make pod correctly shutdown or started                                                                            |
| `edgeNode.extraVolumeMounts`            | `[]`                               | Extra mounts of declared ExtraVolumes into pod                                                                             |
| `edgeNode.extraVolumes`                 | `[]`                               | Extra Volumes declarations to be used in the pod (can be any supported volume type: ConfigMap, Secret, PVC, NFS, etc.)     |
| `customLabels`                          | `{}`                               | Custom labels for k8s resources                                                                                            |


### Configuration for Selenium-Hub

You can configure the Selenium Hub with this values:

| Parameter                       | Default           | Description                                                                                                                      |
| ------------------------------- | ----------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `hub.imageName`                 | `selenium/hub`    | Selenium Hub image name                                                                                                          |
| `hub.imageTag`                  | `nil`             | Selenium Hub image tag (this overwrites `.global.seleniumGrid.imageTag` value)                                                   |
| `hub.imagePullPolicy`           | `IfNotPresent`    | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `hub.imagePullSecret`           | `""`              | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `hub.annotations`               | `{}`              | Custom annotations for Selenium Hub pod                                                                                          |
| `hub.labels`                    | `{}`              | Custom labels for Selenium Hub pod                                                                                               |
| `hub.publishPort`               | `4442`            | Port where events are published                                                                                                  |
| `hub.subscribePort`             | `4443`            | Port where to subscribe for events                                                                                               |
| `hub.port`                      | `4444`            | Selenium Hub port                                                                                                                |
| `hub.livenessProbe`             | `See values.yaml` | Liveness probe settings                                                                                                          |
| `hub.readinessProbe`            | `See values.yaml` | Readiness probe settings                                                                                                         |
| `hub.tolerations`               | `[]`              | Tolerations for selenium-hub pods                                                                                                |
| `hub.nodeSelector`              | `{}`              | Node Selector for selenium-hub pods                                                                                              |
| `hub.priorityClassName`         | `""`              | Priority class name for selenium-hub pods                                                                                        |
| `hub.extraEnvironmentVariables` | `nil`             | Custom environment variables for selenium-hub                                                                                    |
| `hub.extraEnvFrom`              | `nil`             | Custom environment variables for selenium taken from `configMap` or `secret`-hub                                                 |
| `hub.resources`                 | `{}`              | Resources for selenium-hub container                                                                                             |
| `hub.serviceType`               | `NodePort`        | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `hub.loadBalancerIP`            | `nil`             | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| `hub.serviceAnnotations`        | `{}`              | Custom annotations for Selenium Hub service                                                                                      |


### Configuration for isolated components

If you implement selenium-grid with separate components (`isolateComponents: true`), you can configure all components via the following values:

| Parameter                                     | Default                   | Description                                                                                                                      |
| --------------------------------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `components.router.imageName`                 | `selenium/router`         | Router image name                                                                                                                |
| `components.router.imageTag`                  | `nil`                     | Router image tag (this overwrites `.global.seleniumGrid.imageTag` value)                                                         |
| `components.router.imagePullPolicy`           | `IfNotPresent`            | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.router.imagePullSecret`           | `""`                      | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `components.router.annotations`               | `{}`                      | Custom annotations for router pod                                                                                                |
| `components.router.port`                      | `4444`                    | Router port                                                                                                                      |
| `components.router.livenessProbe`             | `See values.yaml`         | Liveness probe settings                                                                                                          |
| `components.router.readinessProbe`            | `See values.yaml`         | Readiness probe settings                                                                                                         |
| `components.router.resources`                 | `{}`                      | Resources for router container                                                                                                   |
| `components.router.serviceType`               | `NodePort`                | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.router.loadBalancerIP`            | `nil`                     | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| `components.router.serviceAnnotations`        | `{}`                      | Custom annotations for router service                                                                                            |
| `components.router.tolerations`               | `[]`                      | Tolerations for router pods                                                                                                      |
| `components.router.nodeSelector`              | `{}`                      | Node Selector for router pods                                                                                                    |
| `components.router.priorityClassName`         | `""`                      | Priority class name for router pods                                                                                              |
| `components.distributor.imageName`            | `selenium/distributor`    | Distributor image name                                                                                                           |
| `components.distributor.imageTag`             | `nil`                     | Distributor image tag  (this overwrites `.global.seleniumGrid.imageTag` value)                                                   |
| `components.distributor.imagePullPolicy`      | `IfNotPresent`            | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.distributor.imagePullSecret`      | `""`                      | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `components.distributor.annotations`          | `{}`                      | Custom annotations for Distributor pod                                                                                           |
| `components.distributor.port`                 | `5553`                    | Distributor port                                                                                                                 |
| `components.distributor.resources`            | `{}`                      | Resources for Distributor container                                                                                              |
| `components.distributor.serviceType`          | `ClusterIP`               | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.distributor.serviceAnnotations`   | `{}`                      | Custom annotations for Distributor service                                                                                       |
| `components.distributor.tolerations`          | `[]`                      | Tolerations for Distributor pods                                                                                                 |
| `components.distributor.nodeSelector`         | `{}`                      | Node Selector for Distributor pods                                                                                               |
| `components.distributor.priorityClassName`    | `""`                      | Priority class name for Distributor pods                                                                                         |
| `components.eventBus.imageName`               | `selenium/event-bus`      | Event Bus image name                                                                                                             |
| `components.eventBus.imageTag`                | `nil`                     | Event Bus image tag  (this overwrites `.global.seleniumGrid.imageTag` value)                                                     |
| `components.eventBus.imagePullPolicy`         | `IfNotPresent`            | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.eventBus.imagePullSecret`         | `""`                      | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `components.eventBus.annotations`             | `{}`                      | Custom annotations for Event Bus pod                                                                                             |
| `components.eventBus.port`                    | `5557`                    | Event Bus port                                                                                                                   |
| `components.eventBus.publishPort`             | `4442`                    | Port where events are published                                                                                                  |
| `components.eventBus.subscribePort`           | `4443`                    | Port where to subscribe for events                                                                                               |
| `components.eventBus.resources`               | `{}`                      | Resources for event-bus container                                                                                                |
| `components.eventBus.serviceType`             | `ClusterIP`               | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.eventBus.serviceAnnotations`      | `{}`                      | Custom annotations for Event Bus service                                                                                         |
| `components.eventBus.tolerations`             | `[]`                      | Tolerations for Event Bus pods                                                                                                   |
| `components.eventBus.nodeSelector`            | `{}`                      | Node Selector for Event Bus pods                                                                                                 |
| `components.eventBus.priorityClassName`       | `""`                      | Priority class name for Event Bus pods                                                                                           |
| `components.sessionMap.imageName`             | `selenium/sessions`       | Session Map image name                                                                                                           |
| `components.sessionMap.imageTag`              | `nil`                     | Session Map image tag  (this overwrites `.global.seleniumGrid.imageTag` value)                                                   |
| `components.sessionMap.imagePullPolicy`       | `IfNotPresent`            | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.sessionMap.imagePullSecret`       | `""`                      | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `components.sessionMap.annotations`           | `{}`                      | Custom annotations for Session Map pod                                                                                           |
| `components.sessionMap.resources`             | `{}`                      | Resources for event-bus container                                                                                                |
| `components.sessionMap.serviceType`           | `ClusterIP`               | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.sessionMap.serviceAnnotations`    | `{}`                      | Custom annotations for Session Map service                                                                                       |
| `components.sessionMap.tolerations`           | `[]`                      | Tolerations for Session Map pods                                                                                                 |
| `components.sessionMap.nodeSelector`          | `{}`                      | Node Selector for Session Map pods                                                                                               |
| `components.sessionMap.priorityClassName`     | `""`                      | Priority class name for Session Map pods                                                                                         |
| `components.sessionQueue.imageName`           | `selenium/session-queue`  | Session Queue image name                                                                                                         |
| `components.sessionQueue.imageTag`            | `nil`                     | Session Queue image tag  (this overwrites `.global.seleniumGrid.imageTag` value)                                                 |
| `components.sessionQueue.imagePullPolicy`     | `IfNotPresent`            | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.sessionQueue.imagePullSecret`     | `""`                      | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry)                     |
| `components.sessionQueue.annotations`         | `{}`                      | Custom annotations for Session Queue pod                                                                                         |
| `components.sessionQueue.resources`           | `{}`                      | Resources for event-bus container                                                                                                |
| `components.sessionQueue.serviceType`         | `ClusterIP`               | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.sessionQueue.serviceAnnotations`  | `{}`                      | Custom annotations for Session Queue service                                                                                     |
| `components.sessionQueue.tolerations`         | `[]`                      | Tolerations for Session Queue pods                                                                                               |
| `components.sessionQueue.nodeSelector`        | `{}`                      | Node Selector for Session Queue pods                                                                                             |
| `components.sessionQueue.priorityClassName`   | `""`                      | Priority class name for Session Queue pods                                                                                       |
| `components.extraEnvironmentVariables`        | `nil`                     | Custom environment variables for all components                                                                                  |
| `components.extraEnvFrom`                     | `nil`                     | Custom environment variables taken from `configMap` or `secret` for all components                                               |

See how to customize a helm chart installation in the [Helm Docs](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing) for more information.
