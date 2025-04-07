# Mthree-T4 Project: Kubernetes Deployment & Monitoring Setup

This guide explains how we deployed and monitored the Mthree-T4 Project using Kubernetes. 
## 🧩 Overview

Our app has 3 main parts:

1. **Frontend** – This is the React app the user sees.
2. **Backend** – This is a Flask API that gives data to the frontend.
3. **Monitoring Tools** – These help us track what’s happening:
   - **Prometheus** – Collects performance data.
   - **Grafana** – Shows dashboards and graphs.
   - **Loki** – Stores logs.
   - **Promtail** – Collects logs from the app and sends them to Loki.

Everything runs in a Kubernetes namespace called `uber`. Each piece runs in its own Pod.

---

## 1. 🌐 Frontend (React App)

### Files:
- `frontend-deployment.yaml`
- `frontend-service.yaml`

### Why It's Needed:
We use these files to launch the React app and make it available in a browser.

### What They Do:
#### `frontend-deployment.yaml`
- Starts the frontend as a Pod using the image `m3t4-frontend:latest`
- Runs only 1 copy (1 replica)
- Uses port `80` inside the container
- Reads API URLs from a config file (ConfigMap)
- Sets up health checks so Kubernetes can see if the app is working properly

#### `frontend-service.yaml`
- Makes the frontend reachable on your computer using port `30080`
- Type `NodePort` means you can visit the app in your browser using:
  ```
  http://<minikube-ip>:30080
  ```

---

## 2. 🛠 Backend (Flask API)

### Files:
- `backend-deployment.yaml`
- `backend-service.yaml`
- `backend-secret.yaml`

### Why It's Needed:
The backend handles login, payments, rides, etc. These files run the backend, connect it to the database, and collect logs and metrics.

### What They Do:
#### `backend-deployment.yaml`
- Runs Flask using Docker image `m3t4-backend:latest`
- Uses port `5000`
- Writes logs to `/app/logs` (so Promtail can read them)
- Prometheus collects metrics from `/metrics` endpoint
- Loads secrets like DB password, Stripe key, JWT secret from `backend-secret`

#### `backend-service.yaml`
- Allows frontend and Prometheus to talk to the backend inside Kubernetes (not exposed outside)

#### `backend-secret.yaml`
- Stores sensitive data securely (DB, JWT keys) so they don’t appear in the YAML files

---

## 3. 📊 Grafana (Dashboards)

### Files:
- `grafana-deployment.yaml`
- `grafana-service.yaml`
- `grafana-datasources-config.yaml`

### Why It's Needed:
Grafana shows dashboards with charts and logs, so we can see how our app is doing.

### What They Do:
#### `grafana-deployment.yaml`
- Starts Grafana on port `3000`
- Loads pre-configured data sources from a ConfigMap

#### `grafana-service.yaml`
- Makes Grafana available inside the cluster
- To access Grafana from browser, we use port-forwarding:
  ```bash
  kubectl port-forward svc/grafana -n uber 3000:3000
  ```

#### `grafana-datasources-config.yaml`
- Automatically connects Grafana to:
  - Prometheus for metrics
  - Loki for logs

---

## 4. 📈 Prometheus (Collecting Metrics)

### Files:
- `prometheus-deployment.yaml`
- `prometheus-service.yaml`
- `prometheus-configmap.yaml`

### Why It's Needed:
Prometheus collects performance data (CPU, memory, request counts) from backend.

### What They Do:
#### `prometheus-deployment.yaml`
- Runs Prometheus using Docker image
- Reads configuration from a config map
- Opens port `9090`

#### `prometheus-service.yaml`
- Makes Prometheus reachable inside Kubernetes
- Also accessible from browser using port-forwarding:
  ```bash
  kubectl port-forward svc/prometheus -n uber 9090:9090
  ```

#### `prometheus-configmap.yaml`
- Tells Prometheus to collect metrics from pods that have this label:
  ```yaml
  prometheus.io/scrape: "true"
  ```

---

## 5. 📚 Loki (Storing Logs)

### Files:
- `loki-deployment.yaml`
- `loki-service.yaml`
- `loki-configmap.yaml`

### Why It's Needed:
Loki stores logs from Promtail and lets Grafana show them.

### What They Do:
#### `loki-deployment.yaml`
- Starts Loki and loads config from a ConfigMap
- Stores logs on disk (inside container)

#### `loki-service.yaml`
- Lets Promtail and Grafana send/read logs using port `3100`

#### `loki-configmap.yaml`
- Sets up retention (how long logs are saved)
- Uses BoltDB and filesystem to store logs

---

## 6. 📤 Promtail (Collecting Logs)

### Files:
- `promtail-daemonset.yaml`
- `promtail-serviceaccount-rbac.yaml`
- `promtail-configmap.yaml`

### Why It's Needed:
Promtail collects logs from backend and system logs. Sends them to Loki.

### What They Do:
#### `promtail-daemonset.yaml`
- Runs Promtail on every node
- Reads logs from `/app/logs` (for backend) and `/var/log/pods` (for all pods)

#### `promtail-serviceaccount-rbac.yaml`
- Gives Promtail permission to read Kubernetes pod details (used for tagging logs)

#### `promtail-configmap.yaml`
- Two log jobs:
  1. Read logs from backend log folder
  2. Read logs from all Kubernetes pods
- Sends all logs to Loki

---

## ✅ Final Notes 

- All components run in the `uber` namespace
- Frontend exposed to browser via port 30080
- Backend metrics scraped by Prometheus
- Logs shipped to Loki by Promtail
- Grafana shows both metrics and logs in dashboards

This setup gives full visibility into how your app is running, using simple, well-connected Kubernetes tools.

