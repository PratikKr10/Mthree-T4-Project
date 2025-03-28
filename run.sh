

echo "Running the application"

set -e

echo "Running the Minikube"
minikube start

echo "Creating namespace"
kubectl create namespace uber

echo "Building the Docker image - backend"
cd Backend
docker build -t backend-api:latest .

echo "Building the Docker image - frontend"
cd ../Frontend
docker build -t frontend:latest .

echo "Loading the images - frontend"
minikube image load frontend:latest

echo "Loading the images - frontend"
minikube image load backend-api:latest

cd ..
echo "Creating the deployment - backend"
kubectl apply -f be-secrets.yaml
kubectl apply -f be-deployment.yaml

echo "Creating the deployment - frontend"
kubectl apply -f fe-deployment.yaml

echo "Porforwarding the services fronend 5173:80 and backend 5000:5000"
kubectl port-forward svc/frontend-service 5173:80 -n uber
kubectl port-forward svc/backend-service 5000:5000 -n uber