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

# Stop any existing port-forwards
echo "🛑 Killing existing kubectl port-forwards (if any)..."
pkill -f "kubectl port-forward" || true
sleep 1

echo "🔁 Starting port-forwarding for all main services in background..."

kubectl port-forward -n $NAMESPACE svc/frontend 3001:80 > frontend.log 2>&1 &
echo "🌍 Frontend → http://localhost:3001"

kubectl port-forward -n $NAMESPACE svc/flask-backend 5000:5000 > backend.log 2>&1 &
echo "🧠 Backend → http://localhost:5000"

kubectl port-forward -n $NAMESPACE svc/grafana 3030:3000 > grafana.log 2>&1 &
echo "📊 Grafana → http://localhost:3030"

kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 > prometheus.log 2>&1 &
echo "📈 Prometheus → http://localhost:9090"

kubectl port-forward -n $NAMESPACE svc/loki 3100:3100 > loki.log 2>&1 &
echo "📁 Loki → http://localhost:3100"

echo "⏳ Waiting a few seconds for port-forwarding to establish..."
sleep 5
ss -tuln | grep -E '3001|5000|3030|9090|3100' || echo "⚠️ Port forwarding failed. Check logs."


echo "✅ All port-forwards started successfully."
