#!/bin/bash
set -e

export KUBECONFIG=/var/lib/jenkins/.kube/config

echo "✅ Minikube is assumed to be running. Proceeding with build and deploy..."

# 🐳 Use Minikube's Docker daemon
echo "🐳 Switching to Minikube Docker daemon..."
eval $(minikube docker-env)

# 🚀 Ensure namespace exists
NAMESPACE="uber"
echo "🚀 Ensuring namespace '$NAMESPACE' exists..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

# 🔨 Build backend image
echo "🔨 Building backend image..."
docker build -t backend-api:latest ./Backend

# 🔨 Build frontend image
echo "🔨 Building frontend image..."
docker build -t frontend:latest ./Frontend

# 📦 Apply Kubernetes manifests
echo "📦 Applying Kubernetes manifests in namespace '$NAMESPACE'..."
kubectl apply -n $NAMESPACE -f k8s/

# ⏳ Wait for frontend pod to be ready
echo "⏳ Waiting for frontend pod to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n $NAMESPACE --timeout=60s || {
  echo "❌ Frontend pod not ready. Exiting."
  exit 1
}

echo "🛑 Killing existing kubectl port-forwards (if any)..."
pkill -f "kubectl port-forward" || true

echo "🔁 Starting port-forwarding for all main services..."

# IP to access from browser on Windows
HOST_IP=172.24.0.1

# ✅ Corrected port-forwarding syntax
kubectl port-forward -n $NAMESPACE svc/frontend 3001:80 &
echo "🌍 Frontend → http://$HOST_IP:3001"

kubectl port-forward -n $NAMESPACE svc/flask-backend 5000:5000 &
echo "🧠 Backend (Flask API) → http://$HOST_IP:5000"

kubectl port-forward -n $NAMESPACE svc/grafana 3030:3000 &
echo "📊 Grafana → http://$HOST_IP:3030"

kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &
echo "📈 Prometheus → http://$HOST_IP:9090"

kubectl port-forward -n $NAMESPACE svc/loki 3100:3100 &
echo "📁 Loki (logs) → http://$HOST_IP:3100"

echo "✅ All port-forwards started successfully."
exit 0
