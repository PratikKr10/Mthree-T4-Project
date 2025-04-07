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


kubectl apply -n $NAMESPACE -f k8s/promtail-daemonset.yaml
kubectl apply -n $NAMESPACE -f k8s/promtail-serviceaccount-rbac.yaml
kubectl apply -n $NAMESPACE -f k8s/secrets
kubectl apply -n $NAMESPACE -f k8s/services

# echo "⚙️ Creating frontend-config configmap dynamically..."

# export MINIKUBE_IP=$(minikube ip)
# export FRONTEND_PORT=$(kubectl get svc -n uber frontend-service -o=jsonpath='{.spec.ports[0].nodePort}')
# export FRONTEND_URL="http://$MINIKUBE_IP:$FRONTEND_PORT"

# kubectl create configmap frontend-config \
#   --from-literal=FRONTEND_URL="$FRONTEND_URL" \
#   --from-literal=VITE_BASE_URL="http://localhost:5000" \
#   --from-literal=VITE_API_URL="http://localhost:5000" \
#   -n uber --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n $NAMESPACE -f k8s/configs
kubectl apply -n $NAMESPACE -f k8s/deployments

echo "✅ Build and deployment completed."
