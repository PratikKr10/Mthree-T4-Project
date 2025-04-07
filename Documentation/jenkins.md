# Jenkins Deployment Documentation for Uber App on Minikube

## ✅ Overview
This document provides a detailed explanation of how Jenkins was successfully configured to build and deploy the full Uber application stack (frontend, backend, and monitoring) inside Minikube running on WSL (Windows Subsystem for Linux). It also discusses the problems encountered during setup and the solutions implemented.

---

## 🔧 Jenkins + Minikube Integration (WSL-Specific Fixes)

### 🧨 Problem:
- Jenkins and WSL users had conflicting Minikube profiles.
- Jenkins could not access the correct kubeconfig or Minikube image cache.

### ✅ Solution:
We isolated Jenkins by setting these environment variables in `run.sh`:
```bash
export HOME=/var/lib/jenkins
export USER=jenkins
export KUBECONFIG=/var/lib/jenkins/.kube/config
export MINIKUBE_HOME=/var/lib/jenkins
```
This ensured:
- Jenkins had its own kubeconfig.
- Jenkins used a dedicated Minikube profile.
- Avoided permission issues between WSL user and Jenkins user.

---

## 🧱 Build & Deploy Script (`run.sh`)

### ✅ What It Does:
1. Builds Docker images inside Minikube Docker daemon:
   ```bash
   eval $(minikube docker-env)
   ```
2. Builds and loads images:
   ```bash
   docker build -t m3t4-backend:latest ./Backend
   docker build -t m3t4-frontend:latest ./Frontend
   minikube image load m3t4-backend:latest
   minikube image load m3t4-frontend:latest
   ```
3. Applies Kubernetes manifests to the `uber` namespace:
   ```bash
   kubectl apply -n uber -f k8s/
   ```

### 🧨 Problems Fixed:
- Pod stuck in `ErrImageNeverPull`
- Wrong Docker context (built outside Minikube)
- Inconsistent images across users

### ✅ Image Pull Fix:
- Used `imagePullPolicy: Never` in all deployment YAMLs to force Kubernetes to use local images

---

## 🚪 Exposing Services via Port-Forward (`host.sh`)

### 🧨 Problem:
- `minikube tunnel` doesn’t work inside WSL due to system permission errors

### ✅ Solution:
Used `kubectl port-forward` to expose services:
```bash
kubectl port-forward svc/frontend-service 3001:80 -n uber
kubectl port-forward svc/flask-backend 5000:5000 -n uber
```
Benefits:
- No need for root permissions
- Works seamlessly inside WSL
- Does not interfere with internal cluster traffic

---

## 🌍 Stripe Integration with `ngrok`

### 🌍 What Problem Did We Face?

Our app (frontend + backend) runs inside **Minikube**, which is like a private mini cloud on our system.  
But Stripe is a **cloud-based service** that needs to:

- Redirect users to your **frontend** after a payment  
- Send **webhook events** (like `payment_success`) to your **backend**

🛑 **The problem**:  
Local services like `http://localhost:5000` or `192.168.x.x` are **not accessible** from the internet.

---

### 💡 What Does `ngrok` Do?

`ngrok` is like a **bridge between the internet and your local machine**.

It creates a **temporary public URL** (like `https://abc123.ngrok.io`) that securely forwards requests to a local port like:

- `http://localhost:3001` → your **React frontend**
- `http://localhost:5000` → your **Flask backend**

---

### ✅ How `ngrok` Helped Specifically

| Use Case                    | Problem Without ngrok                           | How ngrok Helped                            |
|----------------------------|--------------------------------------------------|---------------------------------------------|
| 🔁 Stripe redirects         | Stripe can’t reach `localhost:3001`             | ngrok made a **public frontend URL**        |
| 📩 Stripe webhooks          | Stripe fails to POST to `localhost:5000/webhook`| ngrok gave a **public backend endpoint**    |
| 🌐 Remote testing           | Couldn’t test from mobile or external devices   | ngrok made it **reachable anywhere**        |
| 🔒 HTTPS support            | Stripe requires HTTPS                           | ngrok tunnels are **secure (HTTPS by default)** |

---


### ✅ Config Used (ngrok v3):
```yaml
version: "3"
agent:
  authtoken: <your-ngrok-token>
tunnels:
  frontend:
    proto: http
    addr: 3001
  backend:
    proto: http
    addr: 5000
```

### ✅ Commands:
```bash
ngrok start --all
```

This exposed:
- Frontend via: `https://frontend.ngrok.io`
- Backend via: `https://backend.ngrok.io`

### 🎯 Result:
- Stripe successfully redirected to the frontend after checkout
- Stripe webhook events successfully hit the Flask backend

---

## 📈 Monitoring Stack (Grafana, Prometheus, Loki)

### 🧱 Setup:
- Prometheus scrapes metrics from Flask backend (`/metrics`)
- Logs written to `/app/logs/app.log` using `RotatingFileHandler`
- Promtail runs as a DaemonSet and forwards logs to Loki
- Grafana connects to both Prometheus and Loki

### 🧨 Problem:
- Concern that `ngrok` or `port-forward` might interfere with internal scraping

### ✅ Clarification:
- Prometheus, Loki, and Grafana work entirely **inside the cluster**
- Their services are `ClusterIP` and unaffected by public tunnels
- No conflict occurred

### ✅ Bonus:
- Port-forwarded Grafana (`localhost:3030`) for direct access to dashboards

---

## 🧪 Testing & Final Verifications

| Component     | Status         | Notes |
|---------------|----------------|-------|
| Frontend      | ✅ Up (via ngrok + port-forward) | Public access for Stripe redirects |
| Backend       | ✅ Up (via ngrok + port-forward) | Webhook received by Flask backend |
| Grafana       | ✅ Running (`localhost:3030`)     | Shows metrics + logs |
| Prometheus    | ✅ Scraping metrics from backend | Valid `/metrics` response |
| Loki + Promtail| ✅ Logging working               | Log entries visible in Grafana |
| Jenkins       | ✅ Builds + deploys app in Minikube | Environment isolated and stable |

---

## 📌 Important Notes
- Always run Minikube as the Jenkins user (`/var/lib/jenkins` profile)
- Never run `minikube tunnel` inside WSL — prefer `kubectl port-forward`
- Use `ngrok` for anything requiring public access (like Stripe)
- Use `minikube docker-env` + `image load` for all custom images
- Ensure secrets/configs (e.g., `frontend-config`, Stripe keys) are applied before deployment

---

## ✅ Conclusion
By resolving environment conflicts, Docker context issues, image pull errors, and public exposure limitations, we successfully configured Jenkins to deploy a fullstack application (with monitoring) on Minikube under WSL. The integration now supports Stripe and real-time observability, and is stable across reboots and redeployments.
