---
description: Selenium Grid Node with Dynamic capabilities in Kubernetes cluster
---
# Selenium Grid Node with Dynamic Capabilities in Kubernetes Cluster

### This image provides a [Selenium Grid Node](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node) that creates browser sessions as Kubernetes Jobs on fly, meant to be used together with a [Selenium Grid Hub](https://www.selenium.dev/documentation/grid/getting_started/#hub-and-node), which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

## Dynamic Grid

Grid 4 has the ability to start Docker containers on demand, this means that it starts
a Docker container in the background for each new session request, the test gets executed
there, and when the test completes, the container gets thrown away.

This execution mode can be used either in the Standalone or Node roles. The "dynamic"
execution mode needs to be told what Docker images to use when the containers get started.
Additionally, the Grid needs to know the URI of the Docker daemon. This configuration can
be placed in a local `toml` file.

More details can be seen at the [Dynamic Grid section in GitHub](https://github.com/SeleniumHQ/docker-selenium/tree/trunk#dynamic-grid).

The same Dynamic Grid concept is applied to a Kubernetes cluster. The Grid provisions exactly one browser Pod per session request and deletes it immediately on close.

### Minimal Hub+Node setup

Along with them, reference Kubernetes manifests are available at [kubernetes/DynamicGrid/](https://github.com/SeleniumHQ/docker-selenium/tree/4.41.0-20260222/kubernetes/DynamicGrid). These are intentionally simplex — designed for local practice and getting started quickly.

Browser stereotypes and Dynamic Grid tuning live in a TOML config file, delivered to the Node Pod via a [ConfigMap](https://github.com/SeleniumHQ/docker-selenium/blob/4.41.0-20260222/kubernetes/DynamicGrid/BaseConfig/configmap.yaml):

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: selenium-kubernetes-config
data:
  kubernetes.toml: |
    [kubernetes]
    configs = [
        "selenium/standalone-chrome:4.41.0-20260222", '{"browserName": "chrome", "platformName": "linux"}',
        "selenium/standalone-firefox:4.41.0-20260222", '{"browserName": "firefox", "platformName": "linux"}',
        "selenium/standalone-edge:4.41.0-20260222", '{"browserName": "MicrosoftEdge", "platformName": "linux"}'
    ]
```

The `configs` array pairs each browser image with a capability stereotype JSON string. The Node uses these to match incoming session requests against the right image, spin up the Pod, and report available slots to the Hub.

The [Node deployment](https://github.com/SeleniumHQ/docker-selenium/blob/4.41.0-20260222/kubernetes/DynamicGrid/Hub_Node/node-kubernetes-deployment.yaml) then mounts that ConfigMap as a file and points the Grid node at it:

```yaml
# node-kubernetes-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selenium-node-kubernetes
spec:
  replicas: 1
  template:
    spec:
      serviceAccountName: selenium-node        # needs Pod create/delete RBAC
      terminationGracePeriodSeconds: 300
      containers:
        - name: selenium-node-kubernetes
          image: selenium/node-kubernetes:4.41.0-20260222
          ports:
            - containerPort: 5555
          env:
            - name: SE_EVENT_BUS_HOST
              value: "selenium-hub"
            - name: SE_NODE_SESSION_TIMEOUT
              value: "600"
            - name: SE_DYNAMIC_OVERRIDE_MAX_SESSIONS
              value: "true"
            - name: SE_DYNAMIC_MAX_SESSIONS
              value: "10"
          volumeMounts:
            - name: selenium-config
              mountPath: /opt/selenium/kubernetes.toml  # TOML config path
              subPath: kubernetes.toml
              readOnly: true
            - name: session-assets                      # shared PVC for video/logs
              mountPath: /opt/selenium/assets
      volumes:
        - name: selenium-config
          configMap:
            name: selenium-kubernetes-config            # references the ConfigMap above
        - name: session-assets
          persistentVolumeClaim:
            claimName: selenium-assets
```

Event bus connectivity (host), and node config (session timeout) are passed as environment variables. Browser stereotypes live entirely in the TOML file inside the ConfigMap, keeping them independently updatable without redeploying the Node.

The [RBAC manifest](https://github.com/SeleniumHQ/docker-selenium/blob/4.41.0-20260222/kubernetes/DynamicGrid/BaseConfig/rbac.yaml) grants the Node the minimal permissions needed — `create`, `delete`, and `get` on `pods` and `pods/log` in the configured namespace. No cluster-wide permissions needed.

### Scaling strategy with InheritedPodSpec

[`InheritedPodSpec`](https://github.com/SeleniumHQ/selenium/blob/selenium-4.41.0/java/src/org/openqa/selenium/grid/node/kubernetes/InheritedPodSpec.java) is what makes multi-Node deployments particularly powerful. When the Dynamic Grid Node runs inside Kubernetes, it inspects its own Pod spec and automatically propagates matching fields to every browser Job it creates — tolerations, affinity rules, node selectors, resource requests and limits, image pull secrets, service account, DNS config, security context, and PVC mounts at the assets path.

This means the browser Pods land on exactly the same node pool, zone, or hardware tier as the Dynamic Node that spawned them — with no extra configuration required in the TOML or ConfigMap.

The practical implication: you can deploy **multiple Dynamic Grid Nodes**, each pinned to a different cluster segment via their own `nodeSelector` or `affinity`, and all registered to the same Hub. The Hub distributes session requests across them, and each Node provisions browser Pods that inherit its own placement constraints.

```
                         ┌─────────────────────────────────-┐
                         │             Hub                  │
                         └──────┬──────────────┬───────────-┘
                                │              │
               ┌────────────────▼──┐      ┌───-▼────────────────┐
               │ NodeKubernetes    │      │ NodeKubernetes      │
               │ nodeSelector:     │      │ nodeSelector:       │
               │   zone=us-west    │      │   zone=us-east      │
               └────────┬──────────┘      └────────-┬───────────┘
                        │ inherits spec             │ inherits spec
              ┌─────────▼──────────┐    ┌──────────-▼──────────┐
              │  browser Pod       │    │  browser Pod         │
              │  (us-west, same    │    │  (us-east, same      │
              │   tolerations...)  │    │   tolerations...)    │
              └────────────────────┘    └─────────────────────-┘
```

Teams can keep multiple Dynamic Nodes on standby — lightweight processes consuming minimal resources — and let the browser Pods scale horizontally on demand within each segment. This approach fits naturally into cluster autoscaler workflows: idle Nodes hold their spot in the cluster; browser Jobs drive the actual compute scaling.

This is a genuinely exciting milestone. Teams running large Kubernetes fleets can now enjoy true on-demand browser provisioning without a Docker socket sidecar. The browser Pod starts when the session starts, and disappears the moment it ends. Resources are consumed only when tests are actually running.

### Example of a release with Selenium Grid Server 4.9.0, released on 20230426

```
    Selenium Server 4.41.0
    Release date 20260222


e126989f151e        selenium/node-kubernetes   4
e126989f151e        selenium/node-kubernetes   4.41
e126989f151e        selenium/node-kubernetes   4.41.0
e126989f151e        selenium/node-kubernetes   4.41.0-20260222
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
