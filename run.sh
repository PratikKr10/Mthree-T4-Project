#!/bin/bash
set -e

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

# 🌐 Ask user to port forward
read -p "🌐 Do you want to start a port forward to the frontend service? (y/n): " ANSWER
if [[ "$ANSWER" == "y" ]]; then
  echo "🌍 Starting port-forward to frontend service on http://localhost:8080 ..."
  kubectl port-forward -n $NAMESPACE svc/frontend 8080:80
else
  echo "✅ Setup complete. Port-forward skipped."
fi