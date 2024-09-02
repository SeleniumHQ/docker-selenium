# Selenium-Grid Helm Chart

This chart enables the creation of a Selenium Grid Server in Kubernetes.

## Contents
<!-- TOC -->
* [Selenium-Grid Helm Chart](#selenium-grid-helm-chart)
  * [Contents](#contents)
  * [Introduction](#introduction)
  * [Installing the chart](#installing-the-chart)
    * [Installing the Nightly chart](#installing-the-nightly-chart)
    * [Chart Release Name convention](#chart-release-name-convention)
  * [Enable Selenium Grid Autoscaling](#enable-selenium-grid-autoscaling)
    * [Settings common for both `job` and `deployment` scalingType](#settings-common-for-both-job-and-deployment-scalingtype)
    * [Settings when scalingType with `deployment`](#settings-when-scalingtype-with-deployment-)
    * [Settings when scalingType with `job`](#settings-when-scalingtype-with-job)
    * [Settings fixed-sized thread pool for the Distributor to create new sessions](#settings-fixed-sized-thread-pool-for-the-distributor-to-create-new-sessions)
  * [Updating Selenium-Grid release](#updating-selenium-grid-release)
  * [Uninstalling Selenium Grid release](#uninstalling-selenium-grid-release)
  * [Ingress Configuration](#ingress-configuration)
  * [Configuration](#configuration)
    * [Configuration global](#configuration-global)
      * [Configuration `global.K8S_PUBLIC_IP`](#configuration-globalk8s_public_ip)
    * [Configuration of Nodes](#configuration-of-nodes)
      * [Container ports and Service ports](#container-ports-and-service-ports)
      * [Configuration of shm size limit for browser nodes](#configuration-of-shm-size-limit-for-browser-nodes)
    * [Configuration of Probes](#configuration-of-probes)
      * [Node Probes](#node-probes)
      * [Distributor Probes](#distributor-probes)
      * [Router Probes](#router-probes)
    * [Configuration extra scripts mount to container](#configuration-extra-scripts-mount-to-container)
    * [Configuration of video recorder and video uploader](#configuration-of-video-recorder-and-video-uploader)
      * [Video recorder](#video-recorder)
      * [Video uploader](#video-uploader)
    * [Configuration of Secure Communication](#configuration-of-secure-communication)
      * [Create TLS Secret](#create-tls-secret)
      * [Secure Connection to Selenium Grid components](#secure-connection-to-selenium-grid-components)
      * [Secure Connection to the Ingress proxy](#secure-connection-to-the-ingress-proxy)
      * [TLS termination in the ingress controller, HTTP/2, and related troubleshooting](#tls-termination-in-the-ingress-controller-http2-and-related-troubleshooting)
    * [Node Registration](#node-registration)
    * [Configuration of tracing observability](#configuration-of-tracing-observability)
    * [Configuration of Selenium Grid chart](#configuration-of-selenium-grid-chart)
    * [Configuration of KEDA](#configuration-of-keda)
    * [Configuration of Ingress NGINX Controller](#configuration-of-ingress-nginx-controller)
    * [Configuration of Jaeger](#configuration-of-jaeger)
    * [Configuration for Selenium-Hub](#configuration-for-selenium-hub)
    * [Configuration for isolated components](#configuration-for-isolated-components)
<!-- TOC -->

## Introduction

We offer a Helm chart to simplify the deployment of Selenium Grid Docker images to Kubernetes.
- Table of chart configuration is available in [CONFIGURATION](CONFIGURATION.md).
- Chart changes are tracked in [CHANGELOG](CHANGELOG.md).
- Sanity/Regression tests for the chart features are tracked in [TESTING](TESTING.md).
- There are some reference values file that used to test and deploy Selenium Grid chart. You can find them in [tests/charts/refValues](../../tests/charts/refValues) and [tests/charts/ci](../../tests/charts/ci).

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
# Verify ingress configuration via kubectl get ingress

# Notes: In case you want to set hostname is selenium-grid.local. You need to add the IP and hostname to the local host file in `/etc/hosts`
sudo -- sh -c -e "echo \"$(hostname -i) selenium-grid.local\" >> /etc/hosts"
```

### Installing the Nightly chart

Nightly chart is built from the latest main branch of this repository with using Nightly images. It is not recommended to use this chart in production. It is only for testing purpose. The procedure to install the Nightly chart is the same as the above, only different on the version, it is `1.0.0-nightly`

```bash
# List all versions Nightly in the docker-selenium repo
helm search repo docker-selenium --devel

# Install basic grid Nightly version
helm install selenium-grid docker-selenium/selenium-grid --version 1.0.0-nightly
```

### Chart Release Name convention

By default, all objects created by the chart will be prefixed with the release name. This is to avoid conflicts with other installations of the chart in the same namespace.

- If you want to disable this behavior, you can deploy the chart with the release name is `selenium`.
- You can override the component name via `.nameOverride` in a respective component. For example
    
    ```yaml
    hub:
      nameOverride: my-hub-name
    chromeNode:
      nameOverride: my-chrome-name
    ```

## Enable Selenium Grid Autoscaling

Selenium Grid has the ability to autoscaling browser nodes up/down based on the pending requests in the 
session queue.

To do this [KEDA](https://keda.sh/docs/latest/scalers/selenium-grid-scaler/) is used. When enabling
autoscaling using `autoscaling.enabling` KEDA is installed automatically. To instead use an existing
installation of KEDA you can enable autoscaling with `autoscaling.enableWithExistingKEDA` instead.

KEDA can scale either with
[deployments](https://keda.sh/docs/latest/concepts/scaling-deployments/#scaling-of-deployments-and-statefulsets)
or [jobs](https://keda.sh/docs/latest/concepts/scaling-jobs/) and the charts support both types. This
chart support both modes.  It is controlled with `autoscaling.scalingType` that can be set to either
job (default) or deployment.

### Settings common for both `job` and `deployment` scalingType

There are few settings that are common for both scaling types. These are grouped under `autoscaling.scaledOptions`.

In case individual node should be scaled differently, you can override the upstream settings with `.scaledOptions` for each node type. For example:

```yaml
autoscaling:
  scaledOptions:
    minReplicaCount: 0
    maxReplicaCount: 8
    pollingInterval: 20

chromeNode:
  scaledOptions:
    minReplicaCount: 1
    maxReplicaCount: 16
    pollingInterval: 10
```

### Settings when scalingType with `deployment` 

By default, `autoscaling.terminationGracePeriodSeconds` is set to 3600 seconds. This is used when scalingType is set to `deployment`. You can adjust this value, it will affect to all nodes.

In case individual node which needs to set different period, you can override the upstream settings with `.terminationGracePeriodSeconds` for each node type. Note that override value must be greater than upstream setting to take effect. For example:

```yaml
autoscaling:
  terminationGracePeriodSeconds: 3600 #default
chromeNode:
  terminationGracePeriodSeconds: 7200 #override
firefoxNode:
  terminationGracePeriodSeconds: 1800 #not override
```

When scaling using deployments the HPA choose pods to terminate randomly. If the chosen pod is currently executing a test rather
than being idle, then there is `terminationGracePeriodSeconds` seconds before the test is expected to complete. If your test is
still executing after `terminationGracePeriodSeconds` seconds, it would result in failure as the pod will be killed.

During `terminationGracePeriodSeconds` period, there is `preStop` hook to execute command to wait for the pod can be shut down gracefully which can be defined in `.deregisterLifecycle`
- There is a `_helpers` template with name `seleniumGrid.node.deregisterLifecycle` render value for pod `lifecycle.preStop`. By default, hook to execute the script to drain node and wait for current session to complete if any. The script is stored in node ConfigMap, more details can be seen in config `nodeConfigMap.`
- You can define your custom `preStop` hook which is applied for all nodes via `autoscaling.deregisterLifecycle`
- In case individual node which needs different hook, you can override the upstream settings with `.deregisterLifecycle` for each node type. If you want to disable upstream hook in a node, pass the value as `false`
- If an individual node has settings `.lifecycle` itself, it would take the highest precedence to override the above use cases.

```yaml
autoscaling:
  deregisterLifecycle:
    preStop:
      exec:
        command: ["bash", "-c", "echo 'Your custom preStop hook applied for all nodes'"]
chromeNode:
  deregisterLifecycle: false #disable upstream hook in chrome node
firefoxNode:
  deregisterLifecycle:
    preStop:
      exec:
        command: ["bash", "-c", "echo 'Your custom preStop hook specific for firefox node'"]
edgeNode:
  lifecycle:
    preStop:
      exec:
        command: ["bash", "-c", "echo 'preStop hook is defined in edge node lifecycle itself'"]
```

For other settings that KEDA [ScaledObject spec](https://keda.sh/docs/latest/concepts/scaling-deployments/#scaledobject-spec) supports, you can set them via `autoscaling.scaledObjectOptions`. For example:

```yaml
autoscaling:
  scaledObjectOptions:
    cooldownPeriod: 60
```

### Settings when scalingType with `job`

Settings that KEDA [ScaledJob spec](https://keda.sh/docs/latest/concepts/scaling-jobs/#scaledjob-spec) supports can be set via `autoscaling.scaledJobOptions`.

### Settings fixed-sized thread pool for the Distributor to create new sessions

When enabling autoscaling, the Distributor might be under a high workload with parallelism tests, which are many requests incoming and nodes scaling up simultaneously. (Refer to: [SeleniumHQ/selenium#13723](https://github.com/SeleniumHQ/selenium/issues/13723)).

By default, the Distributor uses a fixed-sized thread pool with default value is `no. of available processors * 3`.

In autoscaling, by default, it will calculate based on `no. of node types * maxReplicaCount`. For example: `autoscaling.scaledOptions.maxReplicaCount=50`, 3 node types (`Chrome, Firefox, Edge` enabled), the value is `50 * 3 + 1 = 151` is set to environment variable `SE_NEW_SESSION_THREAD_POOL_SIZE` to adjust the Distributor config `--newsession-threadpool-size`

You can override the default calculation by another value via `components.distributor.newSessionThreadPoolSize` (in full distributed mode) or `hub.newSessionThreadPoolSize` (in basic mode).

## Updating Selenium-Grid release

Once you have a new chart version, you can update your selenium-grid running:

```bash
helm upgrade selenium-grid docker-selenium/selenium-grid
```

If needed, you can add sidecars for your browser nodes by running:

```bash
helm upgrade selenium-grid docker-selenium/selenium-grid --set 'firefoxNode.enabled=true' --set-json 'firefoxNode.sidecars=[{"name":"my-sidecar","image":"my-sidecar:latest","imagePullPolicy":"IfNotPresent","ports":[{"containerPort":8080, "protocol":"TCP"}],"resources":{"limits":{"memory": "128Mi"},"requests":{"cpu": "100m"}}}]'
```

Note: the parameter used for --set-json is just an example, please refer to [Container Spec](https://www.devspace.sh/component-chart/docs/configuration/containers) for an overview of usable parameters.

## Uninstalling Selenium Grid release

To uninstall:

```bash
helm uninstall selenium-grid
```

## Ingress Configuration

By default, ingress is enabled without annotations set. If NGINX ingress controller is used, you need to set few annotations to override the default timeout values to avoid 504 errors (see [#1808](https://github.com/SeleniumHQ/docker-selenium/issues/1808)). Since in Selenium Grid the default of `SE_NODE_SESSION_TIMEOUT` and `SE_SESSION_REQUEST_TIMEOUT` is `300` seconds.

To make the user experience better, there are few annotations will be set by default if NGINX ingress controller is used. Mostly relates to timeouts and buffer sizes.

If you are not using NGINX ingress controller, you can disable these default annotations by setting `ingress.nginx` to `nil` (aka null) via Helm CLI `--set ingress.nginx=!`) or via an override-values.yaml as below:

```yaml
ingress:
  nginx: !
```

Similarly, if you want to disable a sub-config of `ingress.nginx`. For example: `--set ingress.nginx.proxyBuffer=null`)

You are also able to combine using both default annotations and your own annotations in `ingress.annotations`. Duplicated keys will be merged strategy overwrite with your own annotations in `ingress.annotations` take precedence.

```yaml
ingress:
  nginx:
    proxyTimeout: 3600
  annotations:
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "7200" # This key will take 7200 instead of 3600
```

List mapping of chart values and default annotation(s)

```markdown
# `ingress.nginx.proxyTimeout` pass value to annotation(s)
nginx.ingress.kubernetes.io/proxy-connect-timeout
nginx.ingress.kubernetes.io/proxy-send-timeout
nginx.ingress.kubernetes.io/proxy-read-timeout
nginx.ingress.kubernetes.io/proxy-stream-timeout
nginx.ingress.kubernetes.io/upstream-keepalive-timeout
nginx.ingress.kubernetes.io/ssl-session-timeout

# `ingress.nginx.proxyBuffer` pass value to to annotation(s)
nginx.ingress.kubernetes.io/proxy-request-buffering: "on"
nginx.ingress.kubernetes.io/proxy-buffering: "on"

# `ingress.nginx.proxyBuffer.size` pass value to to annotation(s)
nginx.ingress.kubernetes.io/proxy-buffer-size
nginx.ingress.kubernetes.io/client-body-buffer-size

# `ingress.nginx.proxyBuffer.number` pass value to annotation(s)
nginx.ingress.kubernetes.io/proxy-buffers-number

# `ingress.nginx.websocket` pass boolean value to add backend service has WebSocket request (Hub/Router - noVNC, CDP, etc.)
nginx.org/websocket-services: "{{ template ($.Values.isolateComponents | ternary "seleniumGrid.router.fullname" "seleniumGrid.hub.fullname") $ }}"

# `ingress.nginx.sslPassthrough` pass boolean value to enable SSL Passthrough (when secure connection is enabled in Grid server backend)
nginx.ingress.kubernetes.io/ssl-passthrough: "true"
nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"

# `ingress.nginx.sslSecret` to specify a Secret with the certificate `tls.crt`, key `tls.key`, the name in the form "namespace/secretName"
# By default, it is empty, the chart will use internal TLS secret resource (or the first `secretName` under `ingress.tls` if set)
nginx.ingress.kubernetes.io/proxy-ssl-secret: {{ template "seleniumGrid.tls.fullname" $ }}

# `ingress.nginx.useHttp2` pass boolean value to enable/disable HTTP/2 in TLS termination in the ingress controller
nginx.ingress.kubernetes.io/use-http2: "true"

# `ingress.nginx.upstreamKeepalive` pass value to upstream keepalive
nginx.ingress.kubernetes.io/upstream-keepalive-connections: "10000"
nginx.ingress.kubernetes.io/upstream-keepalive-time: "1h"
nginx.ingress.kubernetes.io/upstream-keepalive-request: "10000"
```

Refer to [NGINX Ingress Controller Annotations](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md) for more details.

Refer to below section [Configuration of Secure Communication] for more details on how to configure secure communication to Ingress proxy.

## Configuration

### Configuration global

Check out list [configuration](CONFIGURATION.md) with config key start with `global.` for more details.

#### Configuration `global.K8S_PUBLIC_IP`

This is the public IP of the host running Kubernetes cluster. Mainly, it is used to construct the URL for the Selenium Grid (Hub or Router) can be accessed from the outside of the cluster for Node register, Grid UI, RemoteWebDriver, etc.
- Ingress is enabled without setting `ingress.hostname`. All the services will be exposed via the public IP is set in `K8S_PUBLIC_IP`.
- Using NodePort to expose the services. All the services will be exposed via the public IP is set in `K8S_PUBLIC_IP`.
- Using LoadBalancer to expose the services. All the services will be exposed via the LB External IP is set in `K8S_PUBLIC_IP`.

For example:
```yaml
global:
  K8S_PUBLIC_IP: "10.10.10.10"
ingress:
    enabled: true
    hostname: ""
hub:
    subPath: "/selenium"
    serviceType: NodePort
```
```
# Source: selenium-grid/templates/node-configmap.yaml

SE_NODE_GRID_URL: 'http://admin:admin@10.10.10.10/selenium'
```
Besides that, from the outside of the cluster, you can access via NodePort `http://10.10.10.10:30444/selenium`

### Configuration of Nodes

#### Container ports and Service ports

By default, Node will use port `5555` to listen on container (following [this](https://www.selenium.dev/documentation/grid/configuration/cli_options/#server)) and expose via Service. You can update this value via `.port` in respective node type. This will be used to set `SE_NODE_PORT` environment variable to pass to option `--port` when starting the node and update in Service accordingly.

By default, if httpGet probes are enabled, it will use `.port` value in respective node type unless you override it via e.g. `.startupProbe.port` `.readinessProbe.port` or `.livenessProbe.port` in respective node type.

In a node container, there are other running services can be exposed. For example: VNC, NoVNC, SSH, etc. You can easily expose them on container via `.ports` and on Service `service.ports` in respective node type.

```yaml
chromeNode:
  port: 6666 # Update `SE_NODE_PORT` to 6666
  nodePort: 30666 # Specify a NodePort to expose `SE_NODE_PORT` to outside traffic
  ports:
    - 5900 # You can give port number alone, default protocol is TCP
    - 7900
  service:
    type: NodePort # Expose entire ports on Service via NodePort
    ports:
      - name: vnc-port
        protocol: TCP
        port: 5900
        targetPort: 5900
        nodePort: 30590 # Specify a NodePort to expose VNC port
      - name: novnc-port
        protocol: TCP
        port: 7900
        targetPort: 7900
        # NodePort will be assigned randomly if not set
edgeNode:
  ports: # You also can give objects following manifest of container ports
    - containerPort: 5900
      name: vnc
      protocol: TCP
    - containerPort: 7900
      name: novnc
      protocol: TCP
```

#### Configuration of shm size limit for browser nodes

By default, node browsers (Chrome/Chromium, Edge) leave the config key `dshmVolumeSizeLimit` as empty. It means the `/dev/shm` volume mount is disabled, and argument `--disable-dev-shm-usage` is passed to the browser via container environment variable (get motivation from [this post](https://www.ministryoftesting.com/articles/navigating-chromedriver-crashes-in-kubernetes-a-tale-of-test-automation-resilience)). You can set another valid value to enable it back. For example:

```yaml
chromeNode:
    dshmVolumeSizeLimit: "2Gi"
edgeNode:
    dshmVolumeSizeLimit: "2Gi"
```

For Firefox node, the default value is kept as `2Gi`. You can override it via `firefoxNode.dshmVolumeSizeLimit`.

### Configuration of Probes

#### Node Probes

By default, `startupProbe` is enabled and `readinessProbe` and `livenessProbe` are disabled. You can enable/disable them via `.startupProbe.enabled` `.readinessProbe.enabled` `.livenessProbe.enabled` in respective node type.

By default, probes are using `httpGet` method to check the node state. It will use `.port` value in respective node type unless you override it via e.g. `.startupProbe.port` `.readinessProbe.port` or `.livenessProbe.port` in respective node type.

Other settings of probe support to override under `.startupProbe` `.readinessProbe` `.livenessProbe` in respective node type.

```markdown
    schema
    path
    port
    initialDelaySeconds
    failureThreshold
    timeoutSeconds
    periodSeconds
    successThreshold
```

You can configure the probes (as Kubernetes [supports](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)) to override the default settings. For example:

```yaml
edgeNode:
  port: 5555
  startupProbe:
    enabled: true
    tcpSocket:
      port: 5555
    failureThreshold: 10
    periodSeconds: 5
```

#### Distributor Probes

By default, `startupProbe`, `readinessProbe` and `livenessProbe` are enabled for this component in both full distributed and Hub-Nodes mode.

There is a script in chart `configs/distributor/distributorProbe.sh` is loaded into ConfigMap and mounted to the container is used by `livenessProbe`. You can customize the script via `--set-file distributorConfigMap.extraScripts.distributorProbe\.sh=/path/to/your_script.sh` or set via YAML values.

There are some reports on a scenario that would be difficult to reproduce or rare: `Grid UI is accessible but no nodes can be fetched or registered. Or something like there are few requests in session queue but could not be accepted. After restarting the Distributor, the issue is resolved`. Based on that, a proactive approach to do automatic restart whenever detecting it is not healthy via `livenessProbe` and the condition check is executed. The script queries GraphQL endpoint to get `sessionCount`, and `sessionQueueSize`. If the `sessionQueueSize` is greater than 0 and `sessionCount` is 0 until the `failureThreshold`, the Distributor will be restarted. You can adjust the threshold as well as interval via probe settings.

#### Router Probes

By default, `startupProbe`, `readinessProbe` and `livenessProbe` are enabled for this component in full distributed mode.

There is a script in chart `configs/router/routerProbe.sh` loaded into ConfigMap and mounted to the container is used by `livenessProbe`. You can customize the script via `--set-file routerConfigMap.extraScripts.routerProbe\.sh=/path/to/your_script.sh` or set via YAML values.

The script checks GraphQL endpoint is reachable. If the `http_code` is not `200` until the `failureThreshold`, the Router will be restarted. You can adjust the threshold as well as interval via probe settings.

### Configuration extra scripts mount to container

This is supported for containers of browser node, video recorder and video uploader. By default, in these containers, there are scripts, config files implemented. In case you want to customize or replace them with your own implementation. Instead of forking the chart, use volume mount. Now, from your external files, you can insert them into ConfigMap via Helm CLI `--set-file` or compose them in your own YAML values file and pass to Helm CLI `--values` when deploying chart. Any files name that you defined will be picked up into ConfigMap and mounted to the container.

```yaml
nodeConfigMap:
  extraScriptsDirectory: "/opt/selenium"
  extraScripts:
    nodePreStop.sh: |
      #!/bin/bash
      echo "Your custom script"

recorderConfigMap:
  extraScriptsDirectory: "/opt/bin"
  extraScripts:
    video.sh: |
        #!/bin/bash
        echo "Your custom script"    
    video_graphQLQuery.sh: |
        #!/bin/bash
        echo "My new script"

uploaderConfigMap:
  extraScriptsDirectory: "/opt/bin"
  extraScripts:
    upload.sh: |
        #!/bin/bash
        echo "Your custom entry point"
  secretFiles:
    upload.conf: |
        [myremote]
        type = s3
```

Via Helm CLI, you can pass your own files to particular config key. Note that, the file name contains dot `.` for file extension, it will impact to the key name convention in Helm CLI. In this case, be careful to escape the dot `.` in the file name. For example a command in Unix:

```bash
helm upgrade -i test \
    --set-file 'nodeConfigMap.extraScripts.nodePreStop\.sh=/path/to/myScript.sh' \
    --set-file 'recorderConfigMap.extraScripts.video\.sh=/path/to/myCustom.sh' \
    selenium-grid
```

Files in `.extraScripts` will be mounted to the container with the same name within directory is defined in `.extraScriptsDirectory`. For example, in the above config, `nodePreStop.sh` will be mounted to `/opt/selenium/nodePreStop.sh` in the node container.


### Configuration of video recorder and video uploader

#### Video recorder

The video recorder is a sidecar deployed with the browser nodes. It is responsible for recording the video of the browser session. The video recorder is disabled by default. To enable it, you need to set the following values:

```yaml
videoRecorder:
  enabled: true
```

At chart deployment level, that config will enable video container always. In addition, you can disable video recording process via session capability `se:recordVideo`. For example in Python binding:

```python
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium import webdriver

options = ChromeOptions()
options.set_capability('se:recordVideo', False)
driver = webdriver.Remote(options=options, command_executor="http://localhost:4444")
```

In recorder container will perform query GraphQL in Hub based on Node SessionId and extract the value of `se:recordVideo` in capabilities before deciding to start video recording process or not. You can customize by reading on section [Configuration extra scripts mount to container](#configuration-extra-scripts-mount-to-container).

#### Video uploader

The uploader is extra utility in the video container. It is responsible for uploading the video to a remote location. The uploader is disabled by default. To enable it, you need to set the following values:

```yaml
videoRecorder:
  uploader:
    enabled: true
```

By default, the uploader uses [RCLONE](https://rclone.org/) to upload the video to a remote location. RCLONE requires a configuration file to define different remote locations. Refer to [RCLONE docs](https://rclone.org/docs/#config-file) for more details. Config file might contain sensitive information such as access key, secret key, etc. hence it is stored in Secret.

The uploader requires `destinationPrefix` to be set. It is used to instruct the uploader where to upload the video. The format of destinationPrefix is `remote-name://bucket-name/path`. The `remote-name` is configured in RCLONE. The `bucket-name` is the name of the bucket in the remote location. The `path` is the path to the folder in the bucket.

By default, the config file is empty. You can override the config file via `--set-file uploaderConfigMap.secretFiles.upload\.conf=/path/to/your_config.conf` or set via YAML values.

For example, to configure an S3 remote hosted on AWS with named `mys3` and the bucket name is `mybucket`, you can set the following values:

```bash
uploaderConfigMap:
  secretFiles:
    upload.conf: |
        [mys3]
        type = s3
        provider = AWS
        env_auth = true
        region = ap-southeast-1
        location_constraint = ap-southeast-1
        acl = private
        access_key_id = xxx
        secret_access_key = xxx

videoRecorder:
  uploader:
    destinationPrefix: "mys3://mybucket/subFolder"
```

You can prepare a config file with multiple remotes are defined. Ensure that `[remoteName]` is unique for each remote.

Instead of using config file, another way that RCLONE also supports to pass the information via environment variables. ENV variable with format: `RCLONE_CONFIG_ + name of remote + _ + name of config file option` (make it all uppercase). In this case the remote name it can only contain letters, digits, or the _ (underscore) character. All those ENV variables can be set via `videoRecorder.uploader.secrets`, it will be stored in Secret.

For example, the same above config can be set via ENV vars as below:

```yaml
videoRecorder:
  uploader:
    destinationPrefix: "mys3://mybucket"
    secrets:
      RCLONE_CONFIG_MYS3_TYPE: "s3"
      RCLONE_CONFIG_MYS3_PROVIDER: "GCS"
      RCLONE_CONFIG_MYS3_ENV_AUTH: "true"
      RCLONE_CONFIG_MYS3_REGION: "asia-southeast1"
      RCLONE_CONFIG_MYS3_LOCATION_CONSTRAINT: "asia-southeast1"
      RCLONE_CONFIG_MYS3_ACL: "private"
      RCLONE_CONFIG_MYS3_ACCESS_KEY_ID: "xxx"
      RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY: "xxx"
      RCLONE_CONFIG_MYS3_ENDPOINT: "https://storage.googleapis.com"
      RCLONE_CONFIG_MYS3_NO_CHECK_BUCKET: "true"
```

Those two ways are equivalent. You can choose one of them or combine them. When both config file and ENV vars are set, value in `upload.conf` will take precedence.

Besides the configuration, the script for entry point of uploader container also needed. You can override the script via `--set-file uploaderConfigMap.extraScripts.upload\.sh=/path/to/your_script.sh` or set via YAML values. For example:

```yaml
uploaderConfigMap:
  extraScripts:
    upload.sh: |
        #!/bin/bash
        echo "Your custom entry point"
```

In case you want to configure another sidecar container for uploader, you can set a name for `videoRecorder.uploader.name` and create a config key with the same name under `videoRecorder` with all the settings for your container. Set name of `videoRecorder.uploader.entryPointFileName` if your container start by a different entry point. For example:

```yaml
uploaderConfigMap:
    extraScripts:
        upload.sh: |
            #!/bin/bash
            echo "Script control the uploader process"

videoRecorder:
    enabled: true
    uploader:
        enabled: true
        name: "s3"
        entryPointFileName: "upload.sh"
        destinationPrefix: "s3://mybucket"
        secrets:
            AWS_REGION: "ap-southeast-1"
            AWS_ACCESS_KEY_ID: "xxxx"
            AWS_SECRET_ACCESS_KEY: "xxxx"
    s3:
        imageRegistry: public.ecr.aws
        imageName: bitnami/aws-cli
        imageTag: latest
```

### Configuration of Secure Communication

Selenium Grid supports secure communication between components. Refer to the [instructions](https://github.com/SeleniumHQ/selenium/blob/trunk/java/src/org/openqa/selenium/grid/commands/security.txt) and [options](https://www.selenium.dev/documentation/grid/configuration/cli_options/#server) are able to configure the secure communication. Below is the details on how to enable secure communication in Selenium Grid chart.

In the chart, there is directory [certs](./certs) contains utility scripts, the default self-signed certificate, private key (as PKCS8 format), and Java Keystore (JKS) to teach Java about secure connection (since we are using a non-standard CA) for your trial, local testing purpose.

You can generate your own self-signed certificate put them in that default directory by using script [certs/gen-cert-helper.sh](./certs/gen-cert-helper.sh) with adjust needed information before deploying chart. The certificate, private key, truststore are mounted to the components via `Secret`.

Usage of [certs/gen-cert-helper.sh](./certs/gen-cert-helper.sh) script:

```bash
# Generate self-signed to target directory (by default output in same directory with script)
./certs/gen-cert-helper.sh -d /path/to/your/
# Add current host IP to the certificate
ADD_IP_ADDRESS=hostname ./certs/gen-cert-helper -d /path/to/your/
# Add multiple IP addresses to the certificate (comma-separated)
ADD_IP_ADDRESS=",IP:10.10.10.10,IP:10.10.11.11" ./certs/gen-cert-helper.sh -d /path/to/your/
# Other environment variables that script consumes
# CERTNAME, STOREPASS, KEYPASS, ALIAS, SERVER_KEYSTORE, BASE64_ONLY
```

#### Create TLS Secret

There are multiple ways to insert your certificate, private key, truststore to the components. You can choose one of following ways:

1. Replace your certificate, private key, truststore to the default directory [certs](./certs) in chart with the same name before deploying the chart.

2. Use Helm CLI to pass your certificate, private key, truststore via `--set-file` when deploying the chart. For example (replace `$RELEASENAME` and `$NAMESPACE` with your values):

    ```bash
    helm upgrade -i $RELEASENAME -n $NAMESPACE docker-selenium/selenium-grid \
        --set tls.enabled=true \
        --set-file tls.secretFiles.tls\.crt=/path/to/your/tls.crt \
        --set-file tls.secretFiles.tls\.key=/path/to/your/tls.key \
        --set-file tls.secretFiles.server\.jks=/path/to/your/server.jks \
        --set-file tls.secretFiles.server\.pass=/path/to/your/server.pass
    ```

3. Create your own TLS Secret with your certificate, private key, truststore and pass the Secret name via `tls.nameOverride` when deploying the chart. For example (replace `$RELEASENAME` and `$NAMESPACE` with your values):

   ```bash
   # Steps to prepare your self-signed certificate
   ./certs/gen-cert-helper.sh -d /path/to/your/
   # Create TLS Secret with your certificate, private key, truststore (or a Secret type kubernetes.io/tls)
   kubectl create secret generic -n $NAMESPACE my-external-tls-secret \
       --from-file=tls.crt=/path/to/your/tls.crt \
       --from-file=tls.key=/path/to/your/tls.key \
       --from-file=server.jks=/path/to/your/server.jks \
       --from-file=server.pass=/path/to/your/server.pass
   # Deploy chart with your external TLS Secret
   helm upgrade -i $RELEASENAME -n $NAMESPACE docker-selenium/selenium-grid \
       --set tls.enabled=true --set tls.nameOverride=my-external-tls-secret
   ```
   
   In case your external secret contains key file names are different with default, you can instruct server to use them via following values:

    ```yaml
    tls:
      enabled: true
      nameOverride: my-external-tls-secret
      certificateFile: "my-tls.crt"
      privateKeyFile: "my-tls.key"
      trustStoreFile: "my-server.jks"
      trustStorePassword: "mytruststorepassword"
    ```

#### Secure Connection to Selenium Grid components

When enabling secure communication between Selenium Grid server components, you need to set the following values:

```yaml
tls:
  enabled: true
```

In additional, if the ingress is enabled, and approach SSL Passthrough is used to ensure the request forwards to the backend components via an encrypted connection.
With `ingress.hostname` is set, the default server TLS secret is also used for hosts TLS secretName when `ingress.tls` is empty. Once you specify `ingress.tls`, your specified secret will be used for hosts TLS secretName. For example

![SeleniumGrid_TLS_SSL-Passthrough](./images/SeleniumGrid_TLS_SSL-Passthrough.png)

```yaml
tls:
  enabled: true

ingress-ngnix:
  enabled: true
```

Below is an example of Grid UI accessible via NodePort with secure connection, and using external TLS Secret (replace `$RELEASENAME` and `$NAMESPACE` with your values):

```bash
helm upgrade -i $RELEASENAME -n $NAMESPACE docker-selenium/selenium-grid \
  --set ingress.enabled=false \
  --set isolateComponents=true \
  --set components.router.serviceType=NodePort \
  --set tls.enabled=true \
  --set tls.nameOverride=my-external-tls-secret
```

Grid UI can be accessed via HTTPS address `https://your.host.public.ip:30444`.

![SeleniumGrid_TLS_WithoutProxy](./images/SeleniumGrid_TLS_WithoutProxy.png)

#### Secure Connection to the Ingress proxy

When enabling secure communication via HTTPS/TLS between the client and the Ingress proxy only (SSL Offloading / aka SSL Termination). The proxy will terminate the TLS connection, decrypt incoming HTTPS traffic and send it to the backend components without encryption. The backend Selenium Grid components doesn't need to understand HTTPS. To enable this mode, you need to set the following values:

```yaml
tls:
  ingress:
    enabled: true
```

![SeleniumGrid_TLS_SSL-Termination](./images/SeleniumGrid_TLS_SSL-Termination.png)

In additional, a self-signed certificate and private key can be generated runtime during the chart deployment for Ingress TLS by setting these values:

```yaml
tls:
  ingress:
    generateTLS: true
    defaultName: "MySelfSignedCert"
    defaultDays: 3650
    defaultCN: "www.domain.com" # Common Name
    defaultSANList:
      - selenium-grid.prod.domain.com # Subject Alternative Name
      - selenium-grid.staging.domain.com
    defaultIPList:
      - 10.87.99.100 # Public IP of the host running K8s or LoadBalancer IP
      - 10.87.100.101

ingress-ngnix:
  enabled: true
```

You can get the `tls.crt` and `tls.key` from the Secret after the chart is deployed. For example (replace `$RELEASENAME` and `$NAMESPACE` with your values):

```bash
kubectl get secret $RELEASENAME-selenium-tls-secret -n $NAMESPACE -o jsonpath="{.data.tls\.crt}" | base64 -d > ./tls.crt
kubectl get secret $RELEASENAME-selenium-tls-secret -n $NAMESPACE -o jsonpath="{.data.tls\.key}" | base64 -d > ./tls.key
```

Below is an example of Grid UI accessible via secure connection to the Ingress proxy with self-signed certificate in external TLS Secret (replace `$RELEASENAME` and `$NAMESPACE` with your values):

```bash
helm upgrade -i $RELEASENAME -n $NAMESPACE docker-selenium/selenium-grid \
  --set ingress.enabled=true \
  --set ingress.hostname="selenium-grid.prod.domain.com" \
  --set tls.ingress.enabled=true \
  --set tls.nameOverride=my-external-tls-secret
```

Grid UI can be accessed via HTTPS address `https://selenium-grid.prod.domain.com`.

Inline config TLS for the Ingress resource is also considered as enable secure connection to the Ingress proxy.
For example, below is the config with using external TLS Secret for the Ingress resource and enable sub-chart NGINX Ingress Controller:

```yaml
ingress:
  enableWithController: true
  hostname: selenium-grid.prod.domain.com
  tls:
    - secretName: my-external-tls-secret
      hosts:
        - selenium-grid.prod.domain.com
```

In case the Ingress resource is configured without `hostname` and `tls`, the incoming traffic access via `global.K8S_PUBLIC_IP`. When sub-chart `ingress-nginx` is enabled (deploy Ingress NGINX Controller together), the default TLS secret can also be assigned via `ingress-nginx.controller.extraArgs.default-ssl-certificate`.
For example (replace `$RELEASENAME` and `$NAMESPACE` with your values):

```bash
helm upgrade -i $RELEASENAME -n $NAMESPACE docker-selenium/selenium-grid \
  --set global.K8S_PUBLIC_IP=$(hostname -i) \
  --set tls.ingress.enableWithController=true \
  --set tls.nameOverride=my-external-tls-secret \
  --set ingress-nginx.controller.extraArgs.default-ssl-certificate=$NAMESPACE/my-external-tls-secret
```

#### TLS termination in the ingress controller, HTTP/2, and related troubleshooting

In case the Selenium Grid is deployed with the Ingress controller in front, and the Ingress controller has configured the secure connection with approach SSL termination to terminate the TLS connection, the backend components (mostly Hub/Router to process the request and return to the client) will receive the incoming in plain HTTP. In a few confirmations (also referred to ChatGPT)

> When TLS termination is performed by an ingress controller, HTTP/2 is typically enabled by default. This is because many ingress controllers are designed to support modern web protocols to ensure better performance and efficiency. For example, popular ingress controllers like NGINX and HAProxy enable HTTP/2 by default when handling HTTPS traffic.

At that time, the Selenium Grid server returns the response in HTTP/1.1. However, this mismatch is not expected to cause any problems. Selenium Grid is using JDKHttpClient to communicate between components since the following OpenJDK [docs](https://openjdk.org/groups/net/httpclient/intro.html) mentioned that

> The Java HTTP Client supports both HTTP/1.1 and HTTP/2. By default, the client will send requests using HTTP/2. Requests sent to servers that do not yet support HTTP/2 will automatically be downgraded to HTTP/1.1

A few reports mention the error `java.io.IOException: HTTP/1.1 header parser received no bytes`, `java.io.IOException: /: GOAWAY received`, or a timed-out issue with a stack trace containing `jdk.internal.net.http.Http2Connection`, or `Http2ClientImpl` when creating a RemoteWebDriver session.

What could be the issue around this? It could be due to different JDK versions used. Since JDK20, the default keepalive timeout has been adjusted; see [docs](https://docs.oracle.com/en/java/javase/20/core/java-networking.html) on `jdk.httpclient.keepalive.timeout` (default to 30). Or it could be `jdk.httpclient.maxstreams` (default to 100) if Grid serves many client requests at the same time, it could reach the maximum stream limit.

In some scenarios, the issue might be resolved by setting ClientConfig with HTTP/1.1 when creating RemoteWebDriver. For example, in Java binding you can try this:

```java
ClientConfig config = ClientConfig.defaultConfig().baseUrl(seleniumGridUrl)
                      .readTimeout(300)
                      .version(HttpClient.Version.HTTP_1_1.name());

driver = RemoteWebDriver.builder().oneOf(new ChromeOptions())
         .config(config).build();
```

With the workaround set http version via ClientConfig also there was a point mentioned that we can understand something like `HTTP/1.1 header parser received no bytes`, or `GOAWAY` is an IOException thrown by client HTTP/2, and when switching client to HTTP/1.1, it could go to a situation that would continue to get "random" IOExceptions with a different message from the server.

For example, in [this case](https://stackoverflow.com/questions/55087292/how-to-handle-http-2-goaway-with-java-net-httpclient) the issue could be due to HTTP/2 configs on Ingress controller. Refer to usage of [Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/) [ConfigMap](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/) settings in NGINX Ingress Controller.

- `use-http2` (default is true) - enable or disable HTTP/2 support in secure connection.
- `upstream-keepalive-timeout` (default to 60) - timeout during which an idle keepalive connection to an upstream server will stay open.
- `upstream-keepalive-connections` (default to 320) - maximum number of idle keepalive connections to upstream servers. When this number is exceeded, the least recently used connections are closed

The above notes are motivated by [SeleniumHQ/selenium#14258](https://github.com/SeleniumHQ/selenium/issues/14258). Kindly let us know if you have further troubleshooting on this.

### Node Registration

To enable secure in the node registration to make sure that the node is one you control and not a rouge node, you can enable and provide a registration secret string to Distributor, Router and
Node servers in config `registrationSecret`. For example:

```yaml
registrationSecret:
  enabled: true
  value: "matchThisSecret"
```

### Configuration of tracing observability

The chart supports tracing observability via Jaeger. To enable it, you need to set the following values:

```yaml
tracing:
  enabled: true
```

With this configuration, by default, Jaeger (all-in-one) will be deployed in the same namespace as Selenium Grid.
The Jaeger UI can be accessed via same ingress with prefix `/jaeger`, for example: `http://your.host.name/jaeger`.
The traces will be collected from all the components of Selenium Grid and can be viewed in the Jaeger UI.

In case you want to use your own existing Jaeger instance, you can set the following values:

```yaml
tracing:
    enabledWithExistingEndpoint: true
    exporter: otlp
    exporterEndpoint: 'http://jaeger.domain.com:4317'
```

By default, the exporter is set to `otlp`. It is wide compatibility with many tracing backends.
Read more: [vendors](https://opentelemetry.io/ecosystem/vendors/) native support OpenTelemetry and guidelines on [integration](https://opentelemetry.io/ecosystem/integrations/)

### Configuration of Selenium Grid chart

Check out list [configuration](CONFIGURATION.md) parameter of chart and their default values for more details.

### Configuration of KEDA

If you are setting `autoscaling.enabled` to `true`, chart KEDA is installed and can be configured with
values with the prefix `keda`. So you can for example set `keda.prometheus.metricServer.enabled` to
`true` to enable the metrics server for KEDA.  See
https://github.com/kedacore/charts/blob/main/keda/README.md for more details.

### Configuration of Ingress NGINX Controller

If you are setting `ingress-nginx.enabled` to `true`, chart Ingress NGINX Controller is installed and can be configured with
values with the prefix `ingress-nginx`. See https://github.com/kubernetes/ingress-nginx for more details.

### Configuration of Jaeger

If you are setting `tracing.enabled` to `true`, chart Jaeger is installed and can be configured with
values with the prefix `jaeger`. See https://github.com/jaegertracing/helm-charts for more details.

### Configuration for Selenium-Hub

You can configure the Selenium Hub with config key starts with `hub.`.

Check out list [configuration](CONFIGURATION.md) parameter of chart and their default values for more details.

### Configuration for isolated components

If you implement selenium-grid with separate components (`isolateComponents: true`), you can configure all components via config key starts with `components.`

Check out list [configuration](CONFIGURATION.md) parameter of chart and their default values for more details.

---
See how to customize a helm chart installation in the [Helm Docs](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing) for more information.
