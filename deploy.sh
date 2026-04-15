#!/bin/bash
set -euo pipefail

if [ -f /etc/rancher/k3s/k3s.yaml ]; then
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
else
  export KUBECONFIG=/etc/kubernetes/admin.conf
fi

echo "=== INSTALL TRAEFIK ==="
helm repo add traefik https://traefik.github.io/charts || true
helm repo update

helm upgrade --install traefik traefik/traefik \
  -n kube-system \
  --create-namespace \
  -f core/traefik/helm-values.yaml

kubectl rollout status deployment traefik -n kube-system --timeout=180s

echo "=== APPLY TRAEFIK MIDDLEWARE ==="
kubectl apply -f core/traefik/middleware.yaml

echo "=== INSTALL CERT-MANAGER ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

kubectl wait --for=condition=Available deployment -n cert-manager --all --timeout=180s

echo "=== WAIT WEBHOOK ==="
sleep 20

echo "=== APPLY ISSUER ==="
kubectl apply -f cert-manager/clusterissuer.yaml

sleep 10

echo "=== INSTALL MONITORING ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace

helm upgrade --install loki grafana/loki-stack \
  -n monitoring \
  --set grafana.enabled=false

kubectl rollout status deployment monitoring-grafana -n monitoring --timeout=180s || true

echo "=== DEPLOY APPS ==="
for dir in apps/*; do
  if [ -d "$dir" ]; then
    echo "Deploying $dir ..."
    kubectl apply -f "$dir"
  fi
done

echo "=== DONE ==="