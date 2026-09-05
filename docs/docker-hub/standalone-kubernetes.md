---
description: Selenium Grid Standalone with Dynamic capabilities in Kubernetes cluster
---
# Selenium Grid Standalone with Dynamic Capabilities in Kubernetes Cluster

### This image provides a [Selenium Grid Standalone](https://www.selenium.dev/documentation/grid/getting_started/#standalone) that creates browser sessions as Kubernetes Jobs on fly, which enables you to run [WebDriver tests remotely](https://www.selenium.dev/documentation/webdriver/drivers/remote_webdriver/).

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

### Minimal setup

Along with them, reference Kubernetes manifests are available at [kubernetes/DynamicGrid/](https://github.com/SeleniumHQ/docker-selenium/tree/4.48.0-20260909/kubernetes/DynamicGrid). These are intentionally simplex — designed for local practice and getting started quickly.

Browser stereotypes and Dynamic Grid tuning live in a TOML config file, delivered to the Node Pod via a [ConfigMap](https://github.com/SeleniumHQ/docker-selenium/blob/4.48.0-20260909/kubernetes/DynamicGrid/BaseConfig/configmap.yaml):

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
        "selenium/standalone-chrome:4.48.0-20260909", '{"browserName": "chrome", "platformName": "linux"}',
        "selenium/standalone-firefox:4.48.0-20260909", '{"browserName": "firefox", "platformName": "linux"}',
        "selenium/standalone-edge:4.48.0-20260909", '{"browserName": "MicrosoftEdge", "platformName": "linux"}'
    ]
```

The `configs` array pairs each browser image with a capability stereotype JSON string. The Node uses these to match incoming session requests against the right image, spin up the Pod, and report available slots to the Hub.

The [Standalone deployment](https://github.com/SeleniumHQ/docker-selenium/blob/kubernetes/DynamicGrid/Standalone/standalone-kubernetes.yaml) then mounts that ConfigMap as a file and points the Grid node at it:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: selenium-standalone-kubernetes
  labels:
    app: selenium-standalone-kubernetes
    se/component: standalone
spec:
  replicas: 1
  selector:
    matchLabels:
      app: selenium-standalone-kubernetes
  template:
    metadata:
      labels:
        app: selenium-standalone-kubernetes
        se/component: standalone
    spec:
      serviceAccountName: selenium-node
      terminationGracePeriodSeconds: 300
      containers:
        - name: selenium-standalone-kubernetes
          image: selenium/standalone-kubernetes:4.48.0-20260909
          ports:
            - containerPort: 4444
          env:
            - name: SE_SESSION_REQUEST_TIMEOUT
              value: "600"
            - name: SE_SESSION_RETRY_INTERVAL
              value: "15"
            - name: SE_ROUTER_USERNAME
              value: "admin"
            - name: SE_ROUTER_PASSWORD
              value: "admin"
            - name: SE_NODE_SESSION_TIMEOUT
              value: "600"
            - name: SE_DYNAMIC_OVERRIDE_MAX_SESSIONS
              value: "true"
            - name: SE_DYNAMIC_MAX_SESSIONS
              value: "10"
          resources:
            requests:
              memory: "512Mi"
              cpu: "0.5"
            limits:
              memory: "2Gi"
              cpu: "1"
          livenessProbe:
            exec:
              command:
                - /bin/sh
                - -c
                - curl -G --fail --silent -u ${SE_ROUTER_USERNAME}:${SE_ROUTER_PASSWORD} localhost:4444/status
            initialDelaySeconds: 30
            timeoutSeconds: 5
          readinessProbe:
            httpGet:
              path: /readyz
              port: 4444
            initialDelaySeconds: 30
            timeoutSeconds: 5
          volumeMounts:
            - name: selenium-config
              mountPath: /opt/selenium/kubernetes.toml
              subPath: kubernetes.toml
              readOnly: true
            - name: session-assets
              mountPath: /opt/selenium/assets
      volumes:
        - name: selenium-config
          configMap:
            name: selenium-kubernetes-config
        - name: session-assets
          persistentVolumeClaim:
            claimName: selenium-assets
---
apiVersion: v1
kind: Service
metadata:
  name: selenium-standalone-kubernetes
spec:
  selector:
    app: selenium-standalone-kubernetes
  ports:
    - name: web
      port: 4444
      targetPort: 4444
      nodePort: 30444
  type: NodePort
```

2. Point your WebDriver tests to http://admin:admin@localhost:30444

3. That's it! 

4. (Optional) To see what is happening inside the container, head to the Grid UI at http://admin:admin@localhost/ui/.

* The example above uses `latest` as a tag, but we recommend to full tag to pin a specific browser and Grid version. Please see [Tagging Conventions](https://github.com/SeleniumHQ/docker-selenium/wiki/Tagging-Convention) for details.

## How to choose the correct tag for you

The tag structure is as follows:

```
selenium/standalone-kubernetes-<Major>.<Minor>.<Patch>-<YYYYMMDD>
```


### Example of a release with Selenium Grid Server 4.48.0, released on 20260909

```
    Selenium Server 4.48.0
    Release date 20260909


e126989f151e        selenium/standalone-kubernetes   4
e126989f151e        selenium/standalone-kubernetes   4.48
e126989f151e        selenium/standalone-kubernetes   4.48.0
e126989f151e        selenium/standalone-kubernetes   4.48.0-20260909
```

With that, you can use any of the different tags to get the most recent release in a simplified way.
