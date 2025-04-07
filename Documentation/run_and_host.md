# Jenkins CI/CD Scripts for Kubernetes Deployment (Beginner-Friendly)

This guide explains how the `run-jenkins.sh` and `host.sh` shell scripts work in the Mthree-T4 project. These scripts help automate deployment and make the app accessible for monitoring and testing.

---

## 🚀 What These Scripts Do

- `run-jenkins.sh`: Builds Docker images, prepares config files, and deploys everything to Kubernetes.
- `host.sh`: Opens all the necessary ports so you can access your app and monitoring tools in a browser.
- `ngrok`: Makes those local services available to the outside world via public URLs.

These tools assume:
- Jenkins is being used.
- Minikube is running as the Kubernetes environment.

---

## 🛠️ `run-jenkins.sh` – Build and Deploy the App

### 🔍 Step-by-step Explanation

```bash
set -e
```
- If any command fails, stop the script immediately.

```bash
export HOME=/var/lib/jenkins
export USER=jenkins
export KUBECONFIG=/var/lib/jenkins/.kube/config
export MINIKUBE_HOME=/var/lib/jenkins
```
- Sets environment variables so Jenkins uses its own home directory and its own Kubernetes and Minikube configs.

```bash
eval $(minikube docker-env)
```
- Tells Docker to use Minikube’s Docker daemon (so the images work inside the cluster).

```bash
NAMESPACE="uber"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE
```
- Ensures the Kubernetes namespace `uber` exists.

```bash
docker build -t backend-api:latest ./Backend
docker build -t frontend:latest ./Frontend
```
- Builds the Docker images for backend and frontend from their respective folders.

```bash
kubectl apply -n $NAMESPACE -f k8s/promtail-daemonset.yaml
kubectl apply -n $NAMESPACE -f k8s/promtail-serviceaccount-rbac.yaml
kubectl apply -n $NAMESPACE -f k8s/secrets
kubectl apply -n $NAMESPACE -f k8s/services
```
- Applies initial Kubernetes configuration (secrets, Promtail, services).

```bash
export MINIKUBE_IP=$(minikube ip)
export FRONTEND_PORT=$(kubectl get svc -n uber frontend-service -o=jsonpath='{.spec.ports[0].nodePort}')
export FRONTEND_URL="http://$MINIKUBE_IP:$FRONTEND_PORT"
```
- Dynamically fetches the frontend’s public IP and port from Minikube.

```bash
kubectl create configmap frontend-config \
  --from-literal=FRONTEND_URL="$FRONTEND_URL" \
  --from-literal=VITE_BASE_URL="http://localhost:5000" \
  --from-literal=VITE_API_URL="http://localhost:5000" \
  -n uber --dry-run=client -o yaml | kubectl apply -f -
```
- Creates or updates a ConfigMap for the frontend with the necessary environment variables.

```bash
kubectl apply -n $NAMESPACE -f k8s/configs
kubectl apply -n $NAMESPACE -f k8s/deployments
```
- Applies monitoring configs (Prometheus/Grafana/Loki) and finally deploys all components (frontend, backend, etc.).

### ✅ End Result
- The app is fully built and deployed in the `uber` namespace.
- All Kubernetes manifests are applied.
- A working frontend ConfigMap is created with dynamic URLs.

---

## 🌐 `host.sh` – Make Everything Accessible

### 🔍 Step-by-step Explanation

```bash
set -e
```
- Stop the script if any command fails.

```bash
pkill -f "kubectl port-forward" || true
```
- Stops any previous port-forwarding sessions so we don’t have conflicts.

```bash
kubectl port-forward -n uber svc/frontend-service 3001:80 &
```
- Makes the frontend accessible at: `http://localhost:3001`

```bash
kubectl port-forward -n uber svc/flask-backend 5000:5000 &
```
- Opens the backend API on: `http://localhost:5000`

```bash
kubectl port-forward -n uber svc/grafana 3030:3000 &
```
- Grafana UI available at: `http://localhost:3030`

```bash
kubectl port-forward -n uber svc/prometheus 9090:9090 &
```
- Prometheus metrics dashboard: `http://localhost:9090`

```bash
kubectl port-forward -n uber svc/loki 3100:3100 &
```
- Loki logs endpoint: `http://localhost:3100`

### ✅ End Result
You can now open all the services in your browser and test everything:
- Frontend UI
- Backend API
- Monitoring dashboards

---

## 🌍 `ngrok` – Make Services Publicly Accessible

### 🔹 When is it used?
After you:
1. Run the Jenkins job (`run-jenkins.sh`)
2. Run `host.sh` to forward local ports

You run these two commands:

```bash
pkill -f ngrok         # 🔄 Stops any running ngrok tunnels
ngrok start --all      # 🚀 Starts all ngrok tunnels as defined in ngrok.yml
```

### 🔍 What does it do?
- `ngrok` creates **secure public URLs** for your local services.
- These can be shared for external access, webhook testing, or remote demos.

### ✅ Example Use Case:
If your app runs at `http://localhost:3001`, ngrok exposes it like:
```
https://fancy-cat-3001.ngrok.io → http://localhost:3001
```

You can now use this link from anywhere in the world.

---

## ✅ Final Summary

| Tool | Purpose | Key Tasks |
|------|---------|-----------|
| `run-jenkins.sh` | Builds images & deploys everything | Builds Docker, applies K8s files, creates configmap |
| `host.sh` | Opens services for access | Port-forwards frontend, backend, Grafana, Prometheus, Loki |
| `ngrok` | Makes local services publicly available | Exposes services via public HTTPS URLs |

These tools work together to fully automate deployment and access to your Kubernetes-based app.

