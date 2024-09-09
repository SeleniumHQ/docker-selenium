# selenium-grid

![Version: 0.35.2](https://img.shields.io/badge/Version-0.35.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.24.0-20240907](https://img.shields.io/badge/AppVersion-4.24.0--20240907-informational?style=flat-square)

A Helm chart for creating a Selenium Grid Server in Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| SeleniumHQ | <selenium-developers@googlegroups.com> | <https://github.com/SeleniumHQ> |

## Source Code

* <https://github.com/SeleniumHQ/docker-selenium>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://jaegertracing.github.io/helm-charts | jaeger | 3.2.0 |
| https://kedacore.github.io/charts | keda | 2.15.1 |
| https://kubernetes.github.io/ingress-nginx | ingress-nginx | 4.11.2 |
| https://prometheus-community.github.io/helm-charts | kube-prometheus-stack | 62.6.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.K8S_PUBLIC_IP | string | `""` | Public IP of the host running Kubernetes cluster. This is used to access the Selenium Grid from outside the cluster when ingress is disabled or enabled without a hostname is set. This is part of constructing SE_NODE_GRID_URL and rewrite URL of `se:vnc`, `se:cdp` in the capabilities when `ingress.hostname` is unset |
| global.seleniumGrid.imageRegistry | string | `"selenium"` | Image registry for all selenium components |
| global.seleniumGrid.imageTag | string | `"4.24.0-20240907"` | Image tag for all selenium components |
| global.seleniumGrid.nodesImageTag | string | `"4.24.0-20240907"` | Image tag for browser's nodes |
| global.seleniumGrid.videoImageTag | string | `"ffmpeg-7.0.2-20240907"` | Image tag for browser's video recorder |
| global.seleniumGrid.kubectlImage | string | `"bitnami/kubectl:latest"` | kubectl image is used to execute kubectl commands in utility jobs |
| global.seleniumGrid.imagePullSecret | string | `""` | Pull secret for all components, can be overridden individually |
| global.seleniumGrid.logLevel | string | `"INFO"` | Log level for all components. Possible values describe here: https://www.selenium.dev/documentation/grid/configuration/cli_options/#logging |
| global.seleniumGrid.defaultNodeStartupProbe | string | `"exec"` | Set default startup probe method for all nodes (supplied values: httpGet, exec). If not set, the default is httpGet |
| global.seleniumGrid.defaultNodeLivenessProbe | string | `"exec"` | Set default readiness probe method for all nodes (supplied values: httpGet, exec). If not set, the default is httpGet |
| global.seleniumGrid.defaultComponentLivenessProbe | string | `"exec"` | Set default liveness probe method for all nodes (supplied values: httpGet, exec). If not set, the default is httpGet |
| global.seleniumGrid.stdoutProbeLog | bool | `false` | Probe logs output can be retrieved using `kubectl logs`. Noted: this will not work if shareProcessNamespace is enabled |
| global.seleniumGrid.revisionHistoryLimit | int | `10` | Specify how many old ReplicaSets for this Deployment you want to retain. The rest will be garbage-collected in the background. |
| global.seleniumGrid.structuredLogs | bool | `false` | Whether to enable structured logging |
| global.seleniumGrid.httpLogs | bool | `false` | Enable http logging. Tracing should be enabled to log http logs. |
| global.seleniumGrid.updateStrategy.type | string | `"Recreate"` | Specify update strategy for all components, can be overridden individually |
| global.seleniumGrid.updateStrategy.rollingUpdate | object | `{"maxSurge":1,"maxUnavailable":0}` | Specify for strategy RollingUpdate |
| global.seleniumGrid.affinity | object | `{}` | Specify affinity for all components, can be overridden individually |
| global.seleniumGrid.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for all components, can be overridden individually |
| tls.nameOverride | string | `nil` | Name of external secret containing the TLS certificate and key |
| tls.enabled | bool | `false` | Enable or disable TLS for the server components (and ingress proxy) |
| tls.ingress.enabled | bool | `false` | Enable or disable TLS for the ingress proxy only |
| tls.ingress.generateTLS | bool | `false` | Use the certificate and key are generated with below settings |
| tls.ingress.defaultName | string | `"SeleniumHQ"` |  |
| tls.ingress.defaultDays | int | `3650` |  |
| tls.ingress.defaultCN | string | `"www.selenium.dev"` |  |
| tls.ingress.defaultSANList | list | `[]` |  |
| tls.ingress.defaultIPList | list | `[]` |  |
| tls.secretFilesImportFrom | string | `"certs/**"` | Cert files will be imported from chart directory if not specified |
| tls.secretFiles | object | `{"server.jks":"","server.pass":"","tls.crt":"","tls.key":""}` | File names for the TLS certificate and key to import |
| tls.certVolumeMountPath | string | `"/opt/selenium/secrets"` | All files for TLS will be mounted to the server components under directory |
| tls.certificateFile | string | `"tls.crt"` | Cert file will be mounted to server components as a volume |
| tls.privateKeyFile | string | `"tls.key"` | Key file will be mounted to server components as a volume |
| tls.trustStoreFile | string | `"server.jks"` | Trust store file will be mounted to server components as a volume |
| tls.trustStorePasswordFile | string | `"server.pass"` | Trust store password file will be mounted to server components as a volume |
| tls.trustStorePassword | string | `""` | Recommend to get from trustStorePasswordFile instead of plain text via env variable |
| tls.disableHostnameVerification | bool | `true` | Disable verification the hostname included in the server's TLS/SSL certificates matches the hostnames provided |
| registrationSecret.enabled | bool | `false` | Enable feature node registration secret to make sure that the node is one you control and not a rouge node |
| registrationSecret.value | string | `"HappyTesting"` | The secret value to be used for node registration |
| basicAuth.enabled | bool | `false` | Enable or disable basic auth for the Hub/Router |
| basicAuth.username | string | `"admin"` | Username for basic auth |
| basicAuth.password | string | `"admin"` | Password for basic auth |
| isolateComponents | bool | `false` | Deploy Router, Distributor, EventBus, SessionMap and Nodes separately |
| serviceAccount.create | bool | `true` | Create a service account for all components |
| serviceAccount.nameOverride | string | `nil` | Override to use an external service account |
| serviceAccount.annotations | object | `{}` | Annotations for the service account |
| rbacRole | object | `{"annotations":{},"nameOverride":null,"rules":[{"apiGroups":["keda.sh"],"resources":["scaledjobs"],"verbs":["get","list","patch","update","delete"]},{"apiGroups":["keda.sh"],"resources":["scaledobjects"],"verbs":["get","list","patch","update","delete"]},{"apiGroups":["autoscaling"],"resources":["horizontalpodautoscalers"],"verbs":["get","list","patch","update","delete"]}]}` | RBAC settings for patching finalizers KEDA scaled resources |
| rbacRoleBinding | object | `{"annotations":{},"nameOverride":null,"roleRef":{"apiGroup":"rbac.authorization.k8s.io","kind":"Role"}}` | RBAC role binding settings for patching finalizers KEDA scaled resources |
| ingress.enabled | bool | `true` | Enable to create ingress resource |
| ingress.enableWithController | bool | `false` | Enable ingress resource with automatically installing Ingress NGINX Controller |
| ingress.className | string | `""` | Name of ingress class to select which controller will implement ingress resource |
| ingress.nginx.websocket | bool | `true` | Enable corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.proxyTimeout | int | `3600` | Set timeout to corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.proxyBuffer.size | string | `"512M"` | Set buffer size to corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.proxyBuffer.number | int | `4` | Set buffer number to corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.sslPassthrough | bool | `true` | Enable corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.sslSecret | string | `""` | Specify a Secret with the certificate `tls.crt`, key `tls.key`, the name in the form "namespace/secretName" for NGINX Ingress Controller |
| ingress.nginx.useHttp2 | bool | `true` | Enables or disables HTTP/2 support in secure connections via annotations for NGINX Ingress Controller |
| ingress.nginx.upstreamKeepalive | object | `{"connections":10000,"requests":10000,"time":"1h"}` | Apply upstream keepalive settings once HTTP/2 is enabled |
| ingress.nginx.upstreamKeepalive.connections | int | `10000` | Set keepalive connections to corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.upstreamKeepalive.time | string | `"1h"` | Set keepalive timeout to corresponding annotations for NGINX Ingress Controller |
| ingress.nginx.upstreamKeepalive.requests | int | `10000` | Set keepalive requests to corresponding annotations for NGINX Ingress Controller |
| ingress.ports.http | int | `80` | Specify HTTP port is exposed by ingress controller |
| ingress.ports.https | int | `443` | Specify HTTPS port is exposed by ingress controller |
| ingress.annotations | object | `{}` | Custom annotations for ingress resource |
| ingress.hostname | string | `""` | Default host for the ingress resource |
| ingress.path | string | `"/"` | Default host path for the ingress resource |
| ingress.pathType | string | `"Prefix"` | Default path type for the ingress resource |
| ingress.paths | list | `[]` | List of paths for the ingress resource. This will override the default path |
| ingress.tls | list | `[]` | TLS backend configuration for ingress resource |
| busConfigMap.nameOverride | string | `nil` | Override the name of the bus configMap |
| busConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| distributorConfigMap.nameOverride | string | `nil` | Override the name of the distributor configMap |
| distributorConfigMap.defaultMode | int | `493` | Default mode for ConfigMap is mounted as file |
| distributorConfigMap.extraScriptsImportFrom | string | `"configs/distributor/**"` | Directory where the extra scripts are imported to ConfigMap by default (if given a relative path, it should be in chart's directory) |
| distributorConfigMap.extraScriptsDirectory | string | `"/opt/bin"` | Directory where the extra scripts are mounted to |
| distributorConfigMap.extraScripts."distributorProbe.sh" | string | `""` |  |
| distributorConfigMap.scriptVolumeMountName | string | `nil` | Name of volume mount is used to mount scripts in the ConfigMap. Default is same as this configMap name |
| distributorConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| routerConfigMap.nameOverride | string | `nil` | Override the name of the router configMap |
| routerConfigMap.defaultMode | int | `493` | Default mode for ConfigMap is mounted as file |
| routerConfigMap.extraScriptsImportFrom | string | `"configs/router/**"` | Directory where the extra scripts are imported to ConfigMap by default (if given a relative path, it should be in chart's directory) |
| routerConfigMap.extraScriptsDirectory | string | `"/opt/bin"` | Directory where the extra scripts are mounted to |
| routerConfigMap.extraScripts."routerGraphQLUrl.sh" | string | `""` |  |
| routerConfigMap.extraScripts."routerProbe.sh" | string | `""` |  |
| routerConfigMap.scriptVolumeMountName | string | `nil` | Name of volume mount is used to mount scripts in the ConfigMap |
| routerConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| nodeConfigMap.nameOverride | string | `nil` | Override the name of the node configMap |
| nodeConfigMap.defaultMode | int | `493` | Default mode for ConfigMap is mounted as file |
| nodeConfigMap.extraScriptsImportFrom | string | `"configs/node/**"` | Directory where the extra scripts are imported to ConfigMap by default (if given a relative path, it should be in chart's directory) |
| nodeConfigMap.extraScriptsDirectory | string | `"/opt/bin"` | Directory where the extra scripts are mounted to |
| nodeConfigMap.extraScripts."nodeGridUrl.sh" | string | `""` |  |
| nodeConfigMap.extraScripts."nodePreStop.sh" | string | `""` |  |
| nodeConfigMap.extraScripts."nodeProbe.sh" | string | `""` |  |
| nodeConfigMap.scriptVolumeMountName | string | `nil` | Name of volume mount is used to mount scripts in the ConfigMap |
| nodeConfigMap.leftoversCleanup.enabled | bool | `false` | Enable feature automatic browser leftovers cleanup stuck browser processes, tmp files |
| nodeConfigMap.leftoversCleanup.jobIntervalInSecs | int | `3600` | Interval in seconds to run the cleanup job |
| nodeConfigMap.leftoversCleanup.browserElapsedTimeInSecs | int | `7200` | Browser process elapsed time in seconds to consider as leftovers |
| nodeConfigMap.leftoversCleanup.tmpFilesAfterDays | int | `1` | Tmp files elapsed time in days to consider as leftovers |
| nodeConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| recorderConfigMap.nameOverride | string | `nil` | Override the name of the recorder configMap |
| recorderConfigMap.defaultMode | int | `493` | Default mode for ConfigMap is mounted as file |
| recorderConfigMap.extraScriptsImportFrom | string | `"configs/recorder/**"` | Directory where the extra scripts are imported to ConfigMap by default (if given a relative path, it should be in chart's directory) |
| recorderConfigMap.extraScriptsDirectory | string | `"/opt/bin"` | Directory where the extra scripts are mounted to |
| recorderConfigMap.extraScripts | string | `nil` | List of extra scripts to be mounted to the container. Format as `filename: content` |
| recorderConfigMap.scriptVolumeMountName | string | `nil` | Name of volume mount is used to mount scripts in the ConfigMap |
| recorderConfigMap.videoVolumeMountName | string | `"videos"` | Directory in container where the videos are stored |
| recorderConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| uploaderConfigMap.nameOverride | string | `nil` | Override the name of the uploader configMap |
| uploaderConfigMap.defaultMode | int | `493` | Default mode for ConfigMap is mounted as file |
| uploaderConfigMap.extraScriptsImportFrom | string | `"configs/uploader/**"` | Directory where the extra scripts are imported to ConfigMap by default (if given a relative path, it should be in chart's directory) |
| uploaderConfigMap.extraScriptsDirectory | string | `"/opt/bin"` | Directory where the extra scripts are mounted to |
| uploaderConfigMap.extraScripts | object | `{"upload.sh":""}` | List of extra scripts to be mounted to the container. Format as `filename: content` |
| uploaderConfigMap.secretFiles | object | `{"upload.conf":"[sample]"}` | Extra files stored in Secret to be mounted to the container. |
| uploaderConfigMap.scriptVolumeMountName | string | `nil` | Name of volume mount is used to mount scripts in the ConfigMap |
| uploaderConfigMap.secretVolumeMountName | string | `nil` | Name of Secret is used to store the `secretFiles` |
| uploaderConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| loggingConfigMap | object | `{"annotations":{},"nameOverride":null}` | ConfigMap that contains common environment variables for Logging (https://www.selenium.dev/documentation/grid/configuration/cli_options/#logging) |
| loggingConfigMap.nameOverride | string | `nil` | Override the name of the logging configMap |
| loggingConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| serverConfigMap.nameOverride | string | `nil` | Override the name of the server configMap |
| serverConfigMap.env | object | `{"SE_JAVA_OPTS":"-Djdk.httpclient.keepalive.timeout=300 -Djdk.httpclient.maxstreams=10000 -XX:+UseZGC","SE_SUPERVISORD_LOG_LEVEL":"info"}` | Extra common environment variables for Server (https://www.selenium.dev/documentation/grid/configuration/cli_options/#server) to server configMap |
| serverConfigMap.annotations | object | `{}` | Custom annotations for configmap |
| secrets.create | bool | `true` | Create the default secret for all components |
| secrets.nameOverride | string | `nil` | Override to use an external secret |
| secrets.env | object | `{"SE_VNC_PASSWORD":"secret"}` | Extra environment variables set to the secret |
| secrets.annotations | object | `{}` | Custom annotations for secret |
| components.router.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| components.router.imageName | string | `"router"` | Router image name |
| components.router.imageTag | string | `nil` | Router image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| components.router.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| components.router.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| components.router.disableUI | bool | `false` | Disable the Grid UI |
| components.router.affinity | object | `{}` | Specify affinity for router pods, this overwrites global.seleniumGrid.affinity parameter |
| components.router.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for router pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| components.router.annotations | object | `{}` | Custom annotations for router pods |
| components.router.port | int | `4444` | Router container port |
| components.router.nodePort | int | `30444` | Router expose NodePort |
| components.router.startupProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":5,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Startup probe settings |
| components.router.readinessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":12,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| components.router.livenessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":10,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Liveness probe settings |
| components.router.resources | object | `{}` | Resources for router container |
| components.router.securityContext | object | `{}` | SecurityContext for router container |
| components.router.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| components.router.loadBalancerIP | string | `""` | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| components.router.serviceAnnotations | object | `{}` | Custom annotations for router service |
| components.router.tolerations | list | `[]` | Tolerations for router pods |
| components.router.nodeSelector | object | `{}` | Node selector for router pods |
| components.router.priorityClassName | string | `""` | Priority class name for router pods |
| components.distributor.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| components.distributor.imageName | string | `"distributor"` | Distributor image name |
| components.distributor.imageTag | string | `nil` | Distributor image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| components.distributor.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| components.distributor.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| components.distributor.newSessionThreadPoolSize | string | `nil` | Configure fixed-sized thread pool for the Distributor to create new sessions as it consumes new session requests from the queue |
| components.distributor.affinity | object | `{}` | Specify affinity for distributor pods, this overwrites global.seleniumGrid.affinity parameter |
| components.distributor.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for Distributor pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| components.distributor.annotations | object | `{}` | Custom annotations for Distributor pods |
| components.distributor.port | int | `5553` | Distributor container port |
| components.distributor.nodePort | int | `30553` | Distributor expose NodePort |
| components.distributor.startupProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":5,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Startup probe settings |
| components.distributor.readinessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":12,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| components.distributor.livenessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":10,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Liveness probe settings |
| components.distributor.resources | object | `{}` | Resources for Distributor container |
| components.distributor.securityContext | object | `{}` | SecurityContext for Distributor container |
| components.distributor.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| components.distributor.serviceAnnotations | object | `{}` | Custom annotations for Distributor service |
| components.distributor.tolerations | list | `[]` | Tolerations for Distributor pods |
| components.distributor.nodeSelector | object | `{}` | Node selector for Distributor pods |
| components.distributor.priorityClassName | string | `""` | Priority class name for Distributor pods |
| components.eventBus.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| components.eventBus.imageName | string | `"event-bus"` | Event Bus image name |
| components.eventBus.imageTag | string | `nil` | Event Bus image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| components.eventBus.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| components.eventBus.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| components.eventBus.affinity | object | `{}` | Specify affinity for Event Bus pods, this overwrites global.seleniumGrid.affinity parameter |
| components.eventBus.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for Event Bus pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| components.eventBus.annotations | object | `{}` | Custom annotations for Event Bus pods |
| components.eventBus.port | int | `5557` | Event Bus container port |
| components.eventBus.nodePort | int | `30557` | Event Bus expose NodePort |
| components.eventBus.publishPort | int | `4442` | Container port where events are published |
| components.eventBus.publishNodePort | int | `30442` | NodePort exposed where events are published |
| components.eventBus.subscribePort | int | `4443` | Container port where to subscribe for events |
| components.eventBus.subscribeNodePort | int | `30443` | NodePort exposed where to subscribe for events |
| components.eventBus.resources | object | `{}` | Resources for event-bus container |
| components.eventBus.securityContext | object | `{}` | SecurityContext for event-bus container |
| components.eventBus.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| components.eventBus.serviceAnnotations | object | `{}` | Custom annotations for Event Bus service |
| components.eventBus.tolerations | list | `[]` | Tolerations for Event Bus pods |
| components.eventBus.nodeSelector | object | `{}` | Node selector for Event Bus pods |
| components.eventBus.priorityClassName | string | `""` | Priority class name for Event Bus pods |
| components.sessionMap.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| components.sessionMap.imageName | string | `"sessions"` | Session Map image name |
| components.sessionMap.imageTag | string | `nil` | Session Map image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| components.sessionMap.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| components.sessionMap.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| components.sessionMap.affinity | object | `{}` | Specify affinity for Session Map pods, this overwrites global.seleniumGrid.affinity parameter |
| components.sessionMap.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for Session Map pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| components.sessionMap.annotations | object | `{}` | Custom annotations for Session Map pods |
| components.sessionMap.port | int | `5556` | Session Map container port |
| components.sessionMap.resources | object | `{}` | Resources for Session Map container |
| components.sessionMap.securityContext | object | `{}` | SecurityContext for Session Map container |
| components.sessionMap.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| components.sessionMap.serviceAnnotations | object | `{}` | Custom annotations for Session Map service |
| components.sessionMap.tolerations | list | `[]` | Tolerations for Session Map pods |
| components.sessionMap.nodeSelector | object | `{}` | Node selector for Session Map pods |
| components.sessionMap.priorityClassName | string | `""` | Priority class name for Session Map pods |
| components.sessionQueue.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| components.sessionQueue.imageName | string | `"session-queue"` | Session Queue image name |
| components.sessionQueue.imageTag | string | `nil` | Session Queue image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| components.sessionQueue.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| components.sessionQueue.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| components.sessionQueue.affinity | object | `{}` | Specify affinity for Session Queue pods, this overwrites global.seleniumGrid.affinity parameter |
| components.sessionQueue.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for Session Queue pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| components.sessionQueue.annotations | object | `{}` | Custom annotations for Session Queue pods |
| components.sessionQueue.port | int | `5559` | Session Queue container port |
| components.sessionQueue.nodePort | int | `30559` | Session Queue expose NodePort |
| components.sessionQueue.resources | object | `{}` | Resources for Session Queue container |
| components.sessionQueue.securityContext | object | `{}` | SecurityContext for Session Queue container |
| components.sessionQueue.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| components.sessionQueue.serviceAnnotations | object | `{}` | Custom annotations for Session Queue service |
| components.sessionQueue.tolerations | list | `[]` | Tolerations for Session Queue pods |
| components.sessionQueue.nodeSelector | object | `{}` | Node selector for Session Queue pods |
| components.sessionQueue.priorityClassName | string | `""` | Priority class name for Session Queue pods |
| components.subPath | string | `""` | Custom sub path for all components |
| components.extraEnvironmentVariables | string | `nil` | Custom environment variables for all components |
| components.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for all components |
| hub.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| hub.imageName | string | `"hub"` | Selenium Hub image name |
| hub.imageTag | string | `nil` | Selenium Hub image tag (this overwrites global.seleniumGrid.imageTag parameter) |
| hub.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| hub.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| hub.affinity | object | `{}` | Specify affinity for Selenium Hub pods, this overwrites global.seleniumGrid.affinity parameter |
| hub.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for Hub pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| hub.annotations | object | `{}` | Custom annotations for Selenium Hub pods |
| hub.labels | object | `{}` | Custom labels for Selenium Hub pods |
| hub.disableUI | bool | `false` | Disable the Grid UI |
| hub.newSessionThreadPoolSize | string | `nil` | Configure fixed-sized thread pool for the Distributor to create new sessions as it consumes new session requests from the queue |
| hub.publishPort | int | `4442` | Port where events are published |
| hub.publishNodePort | int | `31442` | NodePort exposed where events are published |
| hub.subscribePort | int | `4443` | Port where to subscribe for events |
| hub.subscribeNodePort | int | `31443` | NodePort exposed where to subscribe for events |
| hub.port | int | `4444` | Selenium Hub port |
| hub.nodePort | int | `31444` | Selenium Hub expose NodePort |
| hub.startupProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":5,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Startup probe settings |
| hub.readinessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":12,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| hub.livenessProbe | object | `{"enabled":true,"failureThreshold":10,"initialDelaySeconds":10,"path":"/readyz","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Liveness probe settings |
| hub.subPath | string | `""` | Custom sub path for the hub deployment |
| hub.extraEnvironmentVariables | string | `nil` | Custom environment variables for selenium-hub |
| hub.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for selenium-hub |
| hub.extraVolumeMounts | list | `[]` | Extra volume mounts for selenium-hub container |
| hub.extraVolumes | list | `[]` | Extra volumes for selenium-hub pod |
| hub.resources | object | `{}` | Resources for selenium-hub container |
| hub.securityContext | object | `{}` | SecurityContext for selenium-hub container |
| hub.serviceType | string | `"ClusterIP"` | Kubernetes service type (see https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types) |
| hub.loadBalancerIP | string | `""` | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| hub.serviceAnnotations | object | `{}` | Custom annotations for Selenium Hub service |
| hub.tolerations | list | `[]` | Tolerations for selenium-hub pods |
| hub.nodeSelector | object | `{}` | Node selector for selenium-hub pods |
| hub.priorityClassName | string | `""` | Priority class name for selenium-hub pods |
| tracing.enabled | bool | `false` | Enable tracing. Implies installing Jaeger |
| tracing.enabledWithExistingEndpoint | bool | `false` | Enable tracing without automatically installing Jaeger |
| tracing.exporter | string | `"otlp"` | Exporter type for tracing. Recommended `otlp` for wide compatibility with observability backends (e.g. Jaeger, Elastic, etc.) |
| tracing.exporterEndpoint | string | `"http://{{ .Release.Name }}-jaeger-collector.{{ .Release.Namespace }}:4317"` | Exporter endpoint for pushing trace data |
| tracing.globalAutoConfigure | bool | `true` | Enable global auto-configuration for tracing |
| tracing.ingress.enabled | bool | `true` | Enable ingress resource to access the Jaeger |
| tracing.ingress.annotations | string | `nil` | Annotations for Jaeger ingress resource |
| tracing.ingress.paths | list | `[{"backend":{"service":{"name":"{{ .Release.Name }}-jaeger-query","port":{"number":16686}}},"path":"/jaeger","pathType":"Prefix"}]` | Configure paths for Jaeger ingress resource |
| monitoring.enabled | bool | `false` |  |
| monitoring.enabledWithExistingAgent | bool | `false` |  |
| autoscaling.enabled | bool | `false` | Enable autoscaling. Implies installing KEDA |
| autoscaling.enableWithExistingKEDA | bool | `false` | Enable autoscaling without automatically installing KEDA |
| autoscaling.scalingType | string | `"job"` | Which type of KEDA scaling to use: job or deployment |
| autoscaling.annotations | object | `{"helm.sh/hook":"post-install,post-upgrade,post-rollback","helm.sh/hook-weight":"1"}` | Annotations for KEDA resources: ScaledObject and ScaledJob |
| autoscaling.patchObjectFinalizers.enabled | bool | `true` | Enable patching finalizers for KEDA scaled resources. Workaround for Hook post-upgrade selenium-grid/templates/x-node-hpa.yaml failed: object is being deleted: scaledobjects.keda.sh "x" already exists |
| autoscaling.patchObjectFinalizers.activeDeadlineSeconds | int | `120` | Deadline (in seconds) for patch job to complete |
| autoscaling.patchObjectFinalizers.annotations | object | `{"helm.sh/hook":"post-install,post-upgrade,post-rollback,pre-delete","helm.sh/hook-delete-policy":"hook-succeeded,before-hook-creation","helm.sh/hook-weight":"-1"}` | Annotations for patch job |
| autoscaling.scaledOptions | object | `{"maxReplicaCount":8,"minReplicaCount":0,"pollingInterval":10}` | Options for KEDA scaled resources (keep only common options used for both ScaledJob and ScaledObject) |
| autoscaling.scaledOptions.minReplicaCount | int | `0` | Minimum number of replicas |
| autoscaling.scaledOptions.maxReplicaCount | int | `8` | Maximum number of replicas |
| autoscaling.scaledOptions.pollingInterval | int | `10` | Polling interval in seconds |
| autoscaling.scaledJobOptions.scalingStrategy.strategy | string | `"accurate"` | Scaling strategy for KEDA ScaledJob |
| autoscaling.scaledJobOptions.successfulJobsHistoryLimit | int | `0` | Number of Completed jobs should be kept |
| autoscaling.scaledJobOptions.failedJobsHistoryLimit | int | `0` | Number of Failed jobs should be kept (for troubleshooting purposes) |
| autoscaling.scaledJobOptions.jobTargetRef | object | `{"backoffLimit":0,"completions":1,"parallelism":1}` | Specify job target ref for KEDA ScaledJob |
| autoscaling.scaledObjectOptions.scaleTargetRef.kind | string | `"Deployment"` | Target reference for KEDA ScaledObject |
| autoscaling.terminationGracePeriodSeconds | int | `3600` | Define terminationGracePeriodSeconds for scalingType "deployment". Period for `deregisterLifecycle` to gracefully shut down the node before force terminating it |
| autoscaling.deregisterLifecycle | string | `nil` | Define preStop command to shut down the node gracefully when scalingType is set to "deployment" |
| chromeNode.enabled | bool | `true` | Enable chrome nodes |
| chromeNode.deploymentEnabled | bool | `true` | NOTE: Only used when autoscaling.enabled is false Enable creation of Deployment true (default) - if you want long-living pods false - for provisioning your own custom type such as Jobs |
| chromeNode.updateStrategy | object | `{"type":"RollingUpdate"}` | Global update strategy will be overwritten by individual component |
| chromeNode.replicas | int | `1` | Number of chrome nodes |
| chromeNode.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| chromeNode.imageName | string | `"node-chrome"` | Image of chrome nodes |
| chromeNode.imageTag | string | `nil` | Image of chrome nodes (this overwrites global.seleniumGrid.nodesImageTag) |
| chromeNode.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| chromeNode.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| chromeNode.ports | list | `[]` | Extra ports list to enable on the node container (e.g. SSH, VNC, NoVNC, etc.) |
| chromeNode.port | int | `5555` | Node component port |
| chromeNode.nodePort | string | `nil` | Node component expose NodePort |
| chromeNode.affinity | object | `{}` | Specify affinity for chrome-node pods, this overwrites global.seleniumGrid.affinity parameter |
| chromeNode.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for chrome-node pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| chromeNode.annotations | object | `{}` | Annotations for chrome-node pods |
| chromeNode.labels | object | `{}` | Labels for chrome-node pods |
| chromeNode.shareProcessNamespace | bool | `true` | Shared process namespace for chrome-node pods |
| chromeNode.resources.requests | object | `{"cpu":"1","memory":"1Gi"}` | Request resources for chrome-node pods |
| chromeNode.resources.limits | object | `{"cpu":"1","memory":"2Gi"}` | Limit resources for chrome-node pods |
| chromeNode.securityContext | object | `{}` | SecurityContext for chrome-node container |
| chromeNode.tolerations | list | `[]` | Tolerations for chrome-node pods |
| chromeNode.nodeSelector | object | `{}` | Node selector for chrome-node pods |
| chromeNode.hostAliases | string | `nil` | Custom host aliases for chrome nodes |
| chromeNode.extraEnvironmentVariables | string | `nil` | Custom environment variables for chrome nodes |
| chromeNode.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for chrome nodes |
| chromeNode.service.enabled | bool | `true` | Create a service for node |
| chromeNode.service.type | string | `"ClusterIP"` | Service type |
| chromeNode.service.loadBalancerIP | string | `""` | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| chromeNode.service.ports | string | `nil` | Extra ports exposed in node service |
| chromeNode.service.annotations | object | `{}` | Custom annotations for service |
| chromeNode.dshmVolumeSizeLimit | string | `""` | Size limit for DSH volume mounted in container (if not set, default is disabled, e.g "1Gi") |
| chromeNode.priorityClassName | string | `""` | Priority class name for chrome-node pods |
| chromeNode.startupProbe | object | `{"enabled":true,"failureThreshold":12,"initialDelaySeconds":0,"path":"/status","periodSeconds":5,"successThreshold":1,"timeoutSeconds":60}` | Startup probe settings |
| chromeNode.readinessProbe | object | `{"enabled":false,"failureThreshold":10,"initialDelaySeconds":10,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| chromeNode.livenessProbe | object | `{"enabled":false,"failureThreshold":6,"initialDelaySeconds":30,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":60}` | Liveness probe settings |
| chromeNode.terminationGracePeriodSeconds | int | `30` | Time to wait for pod termination |
| chromeNode.deregisterLifecycle | string | `nil` | Define preStop command to shut down the chrome node gracefully. This overwrites autoscaling.deregisterLifecycle |
| chromeNode.lifecycle | object | `{}` | Define postStart and preStop events. This overwrites the defined preStop in deregisterLifecycle if any |
| chromeNode.extraVolumeMounts | list | `[]` | Extra volume mounts for chrome-node container |
| chromeNode.extraVolumes | list | `[]` | Extra volumes for chrome-node pod |
| chromeNode.scaledOptions | string | `nil` | Override the scaled options for chrome nodes |
| chromeNode.scaledJobOptions | string | `nil` | Override the scaledJobOptions for chrome nodes |
| chromeNode.scaledObjectOptions | string | `nil` | Override the scaledObjectOptions for chrome nodes |
| chromeNode.hpa.url | string | `"{{ template \"seleniumGrid.graphqlURL\" . }}"` | Graphql endpoint for the HPA to fetch metrics |
| chromeNode.hpa.browserName | string | `"chrome"` | browserName from the capability |
| chromeNode.hpa.sessionBrowserName | string | `"chrome"` | sessionBrowserName if the browserName is different from the sessionBrowserName |
| chromeNode.hpa.platformName | string | `"linux"` | platformName from the capability |
| chromeNode.hpa.unsafeSsl | string | `"{{ template \"seleniumGrid.graphqlURL.unsafeSsl\" . }}"` | Skip check SSL when connecting to the Graphql endpoint |
| chromeNode.initContainers | list | `[]` | It is used to add initContainers in the same pod of the browser node. It should be set using the --set-json option |
| chromeNode.sidecars | list | `[]` | It is used to add sidecars proxy in the same pod of the browser node. It means it will add a new container to the deployment itself. It should be set using the --set-json option |
| firefoxNode.enabled | bool | `true` | Enable firefox nodes |
| firefoxNode.deploymentEnabled | bool | `true` | NOTE: Only used when autoscaling.enabled is false Enable creation of Deployment true (default) - if you want long living pods false - for provisioning your own custom type such as Jobs |
| firefoxNode.updateStrategy | object | `{"type":"RollingUpdate"}` | Global update strategy will be overwritten by individual component |
| firefoxNode.replicas | int | `1` | Number of firefox nodes |
| firefoxNode.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| firefoxNode.imageName | string | `"node-firefox"` | Image of firefox nodes |
| firefoxNode.imageTag | string | `nil` | Image of firefox nodes (this overwrites global.seleniumGrid.nodesImageTag) |
| firefoxNode.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| firefoxNode.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| firefoxNode.ports | list | `[]` | Extra ports list to enable on the node container (e.g. SSH, VNC, NoVNC, etc.) |
| firefoxNode.port | int | `5555` | Node component port |
| firefoxNode.nodePort | string | `nil` | Node component expose NodePort |
| firefoxNode.affinity | object | `{}` | Specify affinity for firefox-node pods, this overwrites global.seleniumGrid.affinity parameter |
| firefoxNode.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for firefox-node pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| firefoxNode.annotations | object | `{}` | Annotations for firefox-node pods |
| firefoxNode.labels | object | `{}` | Labels for firefox-node pods |
| firefoxNode.tolerations | list | `[]` | Tolerations for firefox-node pods |
| firefoxNode.nodeSelector | object | `{}` | Node selector for firefox-node pods |
| firefoxNode.shareProcessNamespace | bool | `true` | Shared process namespace for firefox-node pods |
| firefoxNode.resources.requests | object | `{"cpu":"1","memory":"1Gi"}` | Request resources for firefox-node pods |
| firefoxNode.resources.limits | object | `{"cpu":"1","memory":"2Gi"}` | Limit resources for firefox-node pods |
| firefoxNode.securityContext | object | `{}` | SecurityContext for firefox-node container |
| firefoxNode.hostAliases | string | `nil` | Custom host aliases for firefox nodes |
| firefoxNode.extraEnvironmentVariables | string | `nil` | Custom environment variables for firefox nodes |
| firefoxNode.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for firefox nodes |
| firefoxNode.service.enabled | bool | `true` | Create a service for node |
| firefoxNode.service.type | string | `"ClusterIP"` | Service type |
| firefoxNode.service.loadBalancerIP | string | `""` | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| firefoxNode.service.ports | string | `nil` | Extra ports exposed in node service |
| firefoxNode.service.annotations | object | `{}` | Custom annotations for service |
| firefoxNode.dshmVolumeSizeLimit | string | `"2Gi"` | Size limit for DSH volume mounted in container (if not set, default is disabled, e.g "1Gi") |
| firefoxNode.priorityClassName | string | `""` | Priority class name for firefox-node pods |
| firefoxNode.startupProbe | object | `{"enabled":true,"failureThreshold":12,"initialDelaySeconds":0,"path":"/status","periodSeconds":5,"successThreshold":1,"timeoutSeconds":60}` | Startup probe settings |
| firefoxNode.readinessProbe | object | `{"enabled":false,"failureThreshold":10,"initialDelaySeconds":10,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| firefoxNode.livenessProbe | object | `{"enabled":false,"failureThreshold":6,"initialDelaySeconds":30,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":60}` | Liveness probe settings |
| firefoxNode.terminationGracePeriodSeconds | int | `30` | Time to wait for pod termination |
| firefoxNode.deregisterLifecycle | string | `nil` | Define preStop command to shuts down the chrome node gracefully. This overwrites autoscaling.deregisterLifecycle |
| firefoxNode.lifecycle | object | `{}` | Define postStart and preStop events. This overwrites the defined preStop in deregisterLifecycle if any |
| firefoxNode.extraVolumeMounts | list | `[]` | Extra volume mounts for firefox-node container |
| firefoxNode.extraVolumes | list | `[]` | Extra volumes for firefox-node pod |
| firefoxNode.scaledOptions | string | `nil` | Override the scaled options for firefox nodes |
| firefoxNode.scaledJobOptions | string | `nil` | Override the scaledJobOptions for firefox nodes |
| firefoxNode.scaledObjectOptions | string | `nil` | Override the scaledObjectOptions for firefox nodes |
| firefoxNode.hpa.url | string | `"{{ template \"seleniumGrid.graphqlURL\" . }}"` | Graphql endpoint for the HPA to fetch metrics |
| firefoxNode.hpa.browserName | string | `"firefox"` | browserName from the capability |
| firefoxNode.hpa.sessionBrowserName | string | `"firefox"` | sessionBrowserName if the browserName is different from the sessionBrowserName |
| firefoxNode.hpa.platformName | string | `"linux"` | platformName from the capability |
| firefoxNode.hpa.unsafeSsl | string | `"{{ template \"seleniumGrid.graphqlURL.unsafeSsl\" . }}"` | Skip check SSL when connecting to the Graphql endpoint |
| firefoxNode.initContainers | list | `[]` | It is used to add initContainers in the same pod of the browser node. It should be set using the --set-json option |
| firefoxNode.sidecars | list | `[]` | It is used to add sidecars proxy in the same pod of the browser node. It means it will add a new container to the deployment itself. It should be set using the --set-json option |
| edgeNode.enabled | bool | `true` | Enable edge nodes |
| edgeNode.deploymentEnabled | bool | `true` | NOTE: Only used when autoscaling.enabled is false Enable creation of Deployment true (default) - if you want long living pods false - for provisioning your own custom type such as Jobs |
| edgeNode.updateStrategy | object | `{"type":"RollingUpdate"}` | Global update strategy will be overwritten by individual component |
| edgeNode.replicas | int | `1` | Number of edge nodes |
| edgeNode.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| edgeNode.imageName | string | `"node-edge"` | Image of edge nodes |
| edgeNode.imageTag | string | `nil` | Image of edge nodes (this overwrites global.seleniumGrid.nodesImageTag) |
| edgeNode.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| edgeNode.imagePullSecret | string | `""` | Image pull secret (see https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/) |
| edgeNode.ports | list | `[]` | Extra ports list to enable on the node container (e.g. SSH, VNC, NoVNC, etc.) |
| edgeNode.port | int | `5555` | Node component port |
| edgeNode.nodePort | string | `nil` | Node component expose NodePort |
| edgeNode.affinity | object | `{}` | Specify affinity for edge-node pods, this overwrites global.seleniumGrid.affinity parameter |
| edgeNode.topologySpreadConstraints | list | `[]` | Specify topologySpreadConstraints for edge-node pods, this overwrites global.seleniumGrid.topologySpreadConstraints parameter |
| edgeNode.annotations | object | `{}` | Annotations for edge-node pods |
| edgeNode.labels | object | `{}` | Labels for edge-node pods |
| edgeNode.tolerations | list | `[]` | Tolerations for edge-node pods |
| edgeNode.nodeSelector | object | `{}` | Node selector for edge-node pods |
| edgeNode.shareProcessNamespace | bool | `true` | Shared process namespace for edge-node pods |
| edgeNode.resources.requests | object | `{"cpu":"1","memory":"1Gi"}` | Request resources for edge-node pods |
| edgeNode.resources.limits | object | `{"cpu":"1","memory":"2Gi"}` | Limit resources for edge-node pods |
| edgeNode.securityContext | object | `{}` | SecurityContext for edge-node container |
| edgeNode.hostAliases | string | `nil` | Custom host aliases for edge nodes |
| edgeNode.extraEnvironmentVariables | string | `nil` | Custom environment variables for edge nodes |
| edgeNode.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for edge nodes |
| edgeNode.service.enabled | bool | `true` | Create a service for node |
| edgeNode.service.type | string | `"ClusterIP"` | Service type |
| edgeNode.service.loadBalancerIP | string | `""` | Set specific loadBalancerIP when serviceType is LoadBalancer (see https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) |
| edgeNode.service.ports | string | `nil` | Extra ports exposed in node service |
| edgeNode.service.annotations | object | `{}` | Custom annotations for service |
| edgeNode.dshmVolumeSizeLimit | string | `""` | Size limit for DSH volume mounted in container (if not set, default is disabled, e.g "1Gi") |
| edgeNode.priorityClassName | string | `""` | Priority class name for edge-node pods |
| edgeNode.startupProbe | object | `{"enabled":true,"failureThreshold":12,"initialDelaySeconds":0,"path":"/status","periodSeconds":5,"successThreshold":1,"timeoutSeconds":60}` | Startup probe settings |
| edgeNode.readinessProbe | object | `{"enabled":false,"failureThreshold":10,"initialDelaySeconds":10,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":10}` | Readiness probe settings |
| edgeNode.livenessProbe | object | `{"enabled":false,"failureThreshold":6,"initialDelaySeconds":30,"path":"/status","periodSeconds":10,"successThreshold":1,"timeoutSeconds":60}` | Liveness probe settings |
| edgeNode.terminationGracePeriodSeconds | int | `30` | Time to wait for pod termination |
| edgeNode.deregisterLifecycle | string | `nil` | Define preStop command to shuts down the chrome node gracefully. This overwrites autoscaling.deregisterLifecycle |
| edgeNode.lifecycle | object | `{}` | Define postStart and preStop events. This overwrites the defined preStop in deregisterLifecycle if any |
| edgeNode.extraVolumeMounts | list | `[]` | Extra volume mounts for edge-node container |
| edgeNode.extraVolumes | list | `[]` | Extra volumes for edge-node pod |
| edgeNode.scaledOptions | string | `nil` | Override the scaled options for edge nodes |
| edgeNode.scaledJobOptions | string | `nil` | Override the scaledJobOptions for edge nodes |
| edgeNode.scaledObjectOptions | string | `nil` | Override the scaledObjectOptions for edge nodes |
| edgeNode.hpa.url | string | `"{{ template \"seleniumGrid.graphqlURL\" . }}"` | Graphql endpoint for the HPA to fetch metrics |
| edgeNode.hpa.browserName | string | `"MicrosoftEdge"` | browserName from the capability |
| edgeNode.hpa.sessionBrowserName | string | `"msedge"` | sessionBrowserName if the browserName is different from the sessionBrowserName |
| edgeNode.hpa.platformName | string | `"linux"` | platformName from the capability |
| edgeNode.hpa.unsafeSsl | string | `"{{ template \"seleniumGrid.graphqlURL.unsafeSsl\" . }}"` | Skip check SSL when connecting to the Graphql endpoint |
| edgeNode.initContainers | list | `[]` | It is used to add initContainers in the same pod of the browser node. It should be set using the --set-json option |
| edgeNode.sidecars | list | `[]` | It is used to add sidecars proxy in the same pod of the browser node. It means it will add a new container to the deployment itself. It should be set using the --set-json option |
| videoRecorder.enabled | bool | `false` | Enable video recording in all browser nodes |
| videoRecorder.name | string | `"video"` | Container name is set to resource specs |
| videoRecorder.imageRegistry | string | `nil` | Registry to pull the image (this overwrites global.seleniumGrid.imageRegistry parameter) |
| videoRecorder.imageName | string | `"video"` | Image of video recorder |
| videoRecorder.imageTag | string | `nil` | Image of video recorder (this overwrites global.seleniumGrid.videoImageTag) |
| videoRecorder.imagePullPolicy | string | `"IfNotPresent"` | Image pull policy (see https://kubernetes.io/docs/concepts/containers/images/#updating-images) |
| videoRecorder.targetFolder | string | `"/videos"` | Directory to store video files in the container |
| videoRecorder.uploader.enabled | bool | `false` | Enable video uploader |
| videoRecorder.uploader.destinationPrefix | string | `nil` | Where to upload the video file e.g. remoteName://bucketName/path. Refer to destination syntax of rclone https://rclone.org/docs/ |
| videoRecorder.uploader.name | string | `nil` | What uploader to use (default is empty, internal upload in video container). See .videRecorder.s3 for how to create a new external sidecar container. |
| videoRecorder.uploader.configFileName | string | `"upload.conf"` | Uploader config file name |
| videoRecorder.uploader.entryPointFileName | string | `"upload.sh"` | Uploader entry point file name |
| videoRecorder.uploader.secrets | string | `nil` | For environment variables used in uploader which contains sensitive information, store in secret and refer envFrom Set config for rclone via ENV var with format: RCLONE_CONFIG_ + name of remote + _ + name of config file option (make it all uppercase) |
| videoRecorder.ports | list | `[9000]` | Video recording container port |
| videoRecorder.resources.requests | object | `{"cpu":"1","memory":"1Gi"}` | Request resources for video recorder pods |
| videoRecorder.resources.limits | object | `{"cpu":"1","memory":"1Gi"}` | Limit resources for video recorder pods |
| videoRecorder.securityContext | string | `nil` | SecurityContext for recorder container |
| videoRecorder.extraEnvironmentVariables | string | `nil` | Extra environment variables for video recorder |
| videoRecorder.extraEnvFrom | string | `nil` | Custom environment variables by sourcing entire configMap, Secret, etc. for video recorder. |
| videoRecorder.terminationGracePeriodSeconds | int | `30` | Terminating grace period for video recorder |
| videoRecorder.startupProbe | object | `{}` | Startup probe settings |
| videoRecorder.livenessProbe | object | `{}` | Liveness probe settings |
| videoRecorder.lifecycle | object | `{}` | Define lifecycle events for video recorder |
| videoRecorder.extraVolumeMounts | list | `[]` | Custom video recorder back-end scripts (video.sh, video_ready.py, etc.) further by ConfigMap. NOTE: For the mount point with the name "video", or "video-scripts", it will override the default. For other names, it will be appended. |
| videoRecorder.extraVolumes | list | `[]` | Extra volumes for video recorder pod |
| videoRecorder.s3 | object | `{"args":[],"command":[],"extraEnvironmentVariables":null,"imageName":"bitnami/aws-cli","imagePullPolicy":"IfNotPresent","imageRegistry":"public.ecr.aws","imageTag":"latest","securityContext":{"runAsUser":0}}` | Container spec for the uploader if above it is defined as "uploader.name: s3" |
| customLabels | object | `{}` | Custom labels for k8s resources |
| keda | object | `{"additionalAnnotations":null,"http":{"timeout":60000},"webhooks":{"enabled":false}}` | Configuration for dependency chart keda |
| ingress-nginx | object | `{"controller":{"admissionWebhooks":{"enabled":false}}}` | Configuration for dependency chart ingress-nginx |
| kube-prometheus-stack | object | `{"cleanPrometheusOperatorObjectNames":true}` | Configuration for dependency chart kube-prometheus-stack |
| jaeger | object | `{"agent":{"enabled":false},"allInOne":{"enabled":true,"extraEnv":[{"name":"QUERY_BASE_PATH","value":"/jaeger"}]},"collector":{"enabled":false},"provisionDataStore":{"cassandra":false},"query":{"enabled":false},"storage":{"type":"badger"}}` | Configuration for dependency chart jaeger |

