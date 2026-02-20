# Dynamic Grid Deployment in Kubernetes Cluster Guide

Noted: Example is tested with simplex Kubernetes cluster on Docker Desktop. Customize YAML resources to fit with your cluster.

This setup is split into:
- `BaseConfig/`: mandatory shared resources
- `Standalone/`: `selenium/standalone-kubernetes` deployment + service
- `Hub_Node/`: `selenium/hub` + `selenium/node-kubernetes` deployments and hub service

All manifests are namespace-agnostic. Use `-n <namespace>` when applying.

## 1. Choose namespace

```bash
kubectl create namespace selenium
```

If namespace already exists, continue.

## 2. Apply mandatory base resources

```bash
kubectl apply -n selenium -f BaseConfig/
```

This creates shared resources:
- `ConfigMap` (`selenium-kubernetes-config`)
- `PersistentVolume` + `PersistentVolumeClaim` (`selenium-assets`)
- `ServiceAccount`, `Role`, `RoleBinding` (`selenium-node`)

## 3. Deploy one runtime mode

Deploy only one mode at a time because both modes expose NodePort `30444`.

### Option A: Standalone

```bash
kubectl apply -n selenium -f Standalone/standalone-kubernetes.yaml
```

Access:
- `http://admin:admin@localhost:30444`

### Option B: Hub + Node

```bash
kubectl apply -n selenium -f Hub_Node/hub-node-kubernetes.yaml
```

Access:
- `http://admin:admin@localhost:30444`

## 4. Verify

```bash
kubectl get pods,svc -n selenium
kubectl get pvc,pv -n selenium
```

## 5. Client connectivity test (Basic Auth)

Grid URL:
- `http://admin:admin@localhost:30444`

Quick status check:

```bash
curl -u admin:admin http://localhost:30444/status
```

Python example:

```python
from selenium import webdriver
from selenium.webdriver.common.by import By

driver = webdriver.Remote(
    command_executor="http://admin:admin@localhost:30444",
    options=webdriver.ChromeOptions(),
)
driver.get("https://www.selenium.dev")
print(driver.title)
driver.quit()
```

## 6. Switch mode (optional)

If you want to change from one mode to another:

```bash
kubectl delete -n selenium -f Standalone/standalone-kubernetes.yaml
kubectl apply -n selenium -f Hub_Node/hub-node-kubernetes.yaml
```

Or the reverse:

```bash
kubectl delete -n selenium -f Hub_Node/hub-node-kubernetes.yaml
kubectl apply -n selenium -f Standalone/standalone-kubernetes.yaml
```

## 7. Cleanup

```bash
kubectl delete -n selenium -f Standalone/standalone-kubernetes.yaml --ignore-not-found
kubectl delete -n selenium -f Hub_Node/hub-node-kubernetes.yaml --ignore-not-found
kubectl delete -n selenium -f BaseConfig/
```
