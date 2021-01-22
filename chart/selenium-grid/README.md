# Selenium-Grid Helm Chart

This chart enables the creation of a Selenium grid server in Kubernetes.

## Installing the chart

To install the selenium-grid helm chart, you can run:

```bash
# Clone the project
git clone https://github.com/pedrodotmc/docker-selenium.git

# Install basic grid
helm install selenium-grid docker-selenium/chart/selenium-grid/.

# Or install full grid (Router, Distributor, EventBus, SessionMap and SessionQueuer components separated)
helm install selenium-grid --set isolateComponents=true docker-selenium/chart/selenium-grid/.
```

## Updating Selenium-Grid release

Once you have a new chart version, you can update your selenium-grid running:

```bash
helm upgrade selenium-grid docker-selenium/chart/selenium-grid/.
```

## Uninstalling Selenium Grid release

To uninstall:

```bash
helm uninstall selenium-grid
```

## Configuration

This table contains the configuration parameters of the chart and their default values:

| Parameter                               | Default                            | Description                                                                                                                |
| --------------------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `isolateComponents`                     | `false`                            | Deploy Router, Distributor, EventBus, SessionMap and Nodes separately                                                      |
| `busConfigMap.name`                     | `selenium-event-bus-config`        | Name of the configmap that contains SE_EVENT_BUS_HOST, SE_EVENT_BUS_PUBLISH_PORT and SE_EVENT_BUS_SUBSCRIBE_PORT variables |
| `busConfigMap.annotations`              | `{}`                               | Custom annotations for configmap                                                                                           |
| `chromeNode.enabled`                    | `true`                             | Enable chrome nodes                                                                                                        |
| `chromeNode.replicas`                   | `1`                                | Number of chrome nodes                                                                                                     |
| `chromeNode.imageName`                  | `selenium/node-chrome`             | Image of chrome nodes                                                                                                      |
| `chromeNode.imageTag`                   | `4.0.0-beta-1-prerelease-20210114` | Image of chrome nodes                                                                                                      |
| `chromeNode.imagePullPolicy`            | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `chromeNode.ports`                      | `[5553]`                           | Port list to enable on container                                                                                           |
| `chromeNode.seleniumPort`               | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `chromeNode.seleniumServicePort`        | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `chromeNode.annotations`                | `{}`                               | Annotations for chrome-node pods                                                                                           |
| `chromeNode.resources`                  | `See values.yaml`                  | Resources for chrome-node container                                                                                        |
| `chromeNode.extraEnvironmentVariables`  | `nil`                              | Custom environment variables for chrome nodes                                                                              |
| `firefoxNode.enabled`                   | `true`                             | Enable firefox nodes                                                                                                       |
| `firefoxNode.replicas`                  | `1`                                | Number of firefox nodes                                                                                                    |
| `firefoxNode.imageName`                 | `selenium/node-firefox`            | Image of firefox nodes                                                                                                     |
| `firefoxNode.imageTag`                  | `4.0.0-beta-1-prerelease-20210114` | Image of firefox nodes                                                                                                     |
| `firefoxNode.imagePullPolicy`           | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `firefoxNode.ports`                     | `[5553]`                           | Port list to enable on container                                                                                           |
| `firefoxNode.seleniumPort`              | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `firefoxNode.seleniumServicePort`       | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `firefoxNode.annotations`               | `{}`                               | Annotations for firefox-node pods                                                                                          |
| `firefoxNode.resources`                 | `See values.yaml`                  | Resources for firefox-node container                                                                                       |
| `firefoxNode.extraEnvironmentVariables` | `nil`                              | Custom environment variables for firefox nodes                                                                             |
| `operaNode.enabled`                     | `true`                             | Enable opera nodes                                                                                                         |
| `operaNode.replicas`                    | `1`                                | Number of opera nodes                                                                                                      |
| `operaNode.imageName`                   | `selenium/node-opera`              | Image of opera nodes                                                                                                       |
| `operaNode.imageTag`                    | `4.0.0-beta-1-prerelease-20210114` | Image of opera nodes                                                                                                       |
| `operaNode.imagePullPolicy`             | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                             |
| `operaNode.ports`                       | `[5553]`                           | Port list to enable on container                                                                                           |
| `operaNode.seleniumPort`                | `5900`                             | Selenium port (spec.ports[0].targetPort in kubernetes service)                                                             |
| `operaNode.seleniumServicePort`         | `6900`                             | Selenium port exposed in service (spec.ports[0].port in kubernetes service)                                                |
| `operaNode.annotations`                 | `{}`                               | Annotations for opera-node pods                                                                                            |
| `operaNode.resources`                   | `See values.yaml`                  | Resources for opera-node container                                                                                         |
| `operaNode.extraEnvironmentVariables`   | `nil`                              | Custom environment variables for firefox nodes                                                                             |
| `customLabels`                          | `{}`                               | Custom labels for k8s resources                                                                                            |


### Configuration for Selenium-Hub

You can configure the Selenium Hub with this values:

| Parameter                       | Default                            | Description                                                                                                                      |
| ------------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `hub.imageName`                 | `selenium/hub`                     | Selenium Hub image name                                                                                                          |
| `hub.imageTag`                  | `4.0.0-beta-1-prerelease-20210114` | Selenium Hub image tag                                                                                                           |
| `hub.imagePullPolicy`           | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `hub.annotations`               | `{}`                               | Custom annotations for Selenium Hub pod                                                                                          |
| `hub.publishPort`               | `4442`                             | Port where events are published                                                                                                  |
| `hub.subscribePort`             | `4443`                             | Port where to subscribe for events                                                                                               |
| `hub.port`                      | `4444`                             | Selenium Hub port                                                                                                                |
| `hub.livenessProbe`             | `See values.yaml`                  | Liveness probe settings                                                                                                          |
| `hub.readinessProbe`            | `See values.yaml`                  | Readiness probe settings                                                                                                         |
| `hub.extraEnvironmentVariables` | `nil`                              | Custom environment variables for selenium-hub                                                                                    |
| `hub.resources`                 | `{}`                               | Resources for selenium-hub container                                                                                             |
| `hub.serviceType`               | `NodePort`                         | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `hub.serviceAnnotations`        | `{}`                               | Custom annotations for Selenium Hub service                                                                                      |


### Configuration for isolated components

If you implement selenium-grid with separate components (`isolateComponents: true`), you can configure all components via the following values:

| Parameter                                     | Default                            | Description                                                                                                                      |
| --------------------------------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `components.router.imageName`                 | `selenium/router`                  | Router image name                                                                                                                |
| `components.router.imageTag`                  | `4.0.0-beta-1-prerelease-20210114` | Router image tag                                                                                                                 |
| `components.router.imagePullPolicy`           | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.router.annotations`               | `{}`                               | Custom annotations for router pod                                                                                                |
| `components.router.port`                      | `4444`                             | Router port                                                                                                                      |
| `components.router.livenessProbe`             | `See values.yaml`                  | Liveness probe settings                                                                                                          |
| `components.router.readinessProbe`            | `See values.yaml`                  | Readiness probe settings                                                                                                         |
| `components.router.resources`                 | `{}`                               | Resources for router container                                                                                                   |
| `components.router.serviceType`               | `NodePort`                         | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.router.serviceAnnotations`        | `{}`                               | Custom annotations for router service                                                                                            |
| `components.distributor.imageName`            | `selenium/distributor`             | Distributor image name                                                                                                           |
| `components.distributor.imageTag`             | `4.0.0-beta-1-prerelease-20210114` | Distributor image tag                                                                                                            |
| `components.distributor.imagePullPolicy`      | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.distributor.annotations`          | `{}`                               | Custom annotations for Distributor pod                                                                                           |
| `components.distributor.port`                 | `5553`                             | Distributor port                                                                                                                 |
| `components.distributor.resources`            | `{}`                               | Resources for Distributor container                                                                                              |
| `components.distributor.serviceType`          | `ClusterIP`                        | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.distributor.serviceAnnotations`   | `{}`                               | Custom annotations for Distributor service                                                                                       |
| `components.eventBus.imageName`               | `selenium/event-bus`               | Event Bus image name                                                                                                             |
| `components.eventBus.imageTag`                | `4.0.0-beta-1-prerelease-20210114` | Event Bus image tag                                                                                                              |
| `components.eventBus.imagePullPolicy`         | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.eventBus.annotations`             | `{}`                               | Custom annotations for Event Bus pod                                                                                             |
| `components.eventBus.port`                    | `5557`                             | Event Bus port                                                                                                                   |
| `components.eventBus.publishPort`             | `4442`                             | Port where events are published                                                                                                  |
| `components.eventBus.subscribePort`           | `4443`                             | Port where to subscribe for events                                                                                               |
| `components.eventBus.resources`               | `{}`                               | Resources for event-bus container                                                                                                |
| `components.eventBus.serviceType`             | `ClusterIP`                        | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.eventBus.serviceAnnotations`      | `{}`                               | Custom annotations for Event Bus service                                                                                         |
| `components.sessionMap.imageName`             | `selenium/sessions`                | Session Map image name                                                                                                           |
| `components.sessionMap.imageTag`              | `4.0.0-beta-1-prerelease-20210114` | Session Map image tag                                                                                                            |
| `components.sessionMap.imagePullPolicy`       | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.sessionMap.annotations`           | `{}`                               | Custom annotations for Session Map pod                                                                                           |
| `components.sessionMap.resources`             | `{}`                               | Resources for event-bus container                                                                                                |
| `components.sessionMap.serviceType`           | `ClusterIP`                        | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.sessionMap.serviceAnnotations`    | `{}`                               | Custom annotations for Session Map service                                                                                       |
| `components.sessionQueuer.imageName`          | `selenium/session-queuer`          | Session Queuer image name                                                                                                        |
| `components.sessionQueuer.imageTag`           | `4.0.0-beta-1-prerelease-20210114` | Session Queuer image tag                                                                                                         |
| `components.sessionQueuer.imagePullPolicy`    | `IfNotPresent`                     | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images)                                   |
| `components.sessionQueuer.annotations`        | `{}`                               | Custom annotations for Session Queuer pod                                                                                        |
| `components.sessionQueuer.resources`          | `{}`                               | Resources for event-bus container                                                                                                |
| `components.sessionQueuer.serviceType`        | `ClusterIP`                        | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| `components.sessionQueuer.serviceAnnotations` | `{}`                               | Custom annotations for Session Queuer service                                                                                    |
| `components.extraEnvironmentVariables`        | `nil`                              | Custom environment variables for all components                                                                                  |

See how to customize a helm chart installation in the [Helm Docs](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing) for more information.
