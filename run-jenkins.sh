#!/bin/bash
set -e


# ✅ Force Jenkins to use its own home and kube config
export HOME=/var/lib/jenkins
export USER=jenkins
export KUBECONFIG=/var/lib/jenkins/.kube/config

# ✅ Force minikube to use the Jenkins-specific profile directory
export MINIKUBE_HOME=/var/lib/jenkins

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

echo "✅ Build and deployment completed."
