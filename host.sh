#!/bin/bash

set -e

NAMESPACE="uber"

echo "🛑 Killing existing port-forwards..."
pkill -f "kubectl port-forward" || true

echo "🔁 Starting kubectl port-forwards..."

# ❌ Removed frontend port-forward (served via NodePort now)

kubectl port-forward -n $NAMESPACE svc/flask-backend 5000:5000 &
echo "🧠 Backend → http://localhost:5000"

kubectl port-forward -n $NAMESPACE svc/grafana 3030:3000 &
echo "📊 Grafana → http://localhost:3030"

kubectl port-forward -n $NAMESPACE svc/prometheus 9090:9090 &
echo "📈 Prometheus → http://localhost:9090"

kubectl port-forward -n $NAMESPACE svc/loki 3100:3100 &
echo "📁 Loki → http://localhost:3100"
