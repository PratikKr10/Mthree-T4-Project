#!/bin/bash

set -e

NAMESPACE="uber"

echo "🛑 Killing existing port-forwards..."
pkill -f "kubectl port-forward" || true

echo "🔁 Starting kubectl port-forwards..."

kubectl port-forward -n $NAMESPACE svc/frontend-service 3001:80 &
echo "🧠 Frontend → http://localhost:3001"

kubectl port-forward -n $NAMESPACE svc/flask-backend 5000:5000 &
echo "🧠 Backend → http://localhost:5000"

kubectl port-forward -n $NAMESPACE svc/grafana 3030:3000 &
echo "📊 Grafana → http://localhost:3030"

kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &
echo "📈 Prometheus → http://localhost:9090"

kubectl port-forward -n $NAMESPACE svc/loki 3100:3100 &
echo "📁 Loki → http://localhost:3100"
