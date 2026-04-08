#!/bin/bash
set -euo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "=== INSTALL TRAEFIK ==="
helm repo add traefik https://traefik.github.io/charts || true
helm repo update

helm upgrade --install traefik traefik/traefik \
  -n kube-system \
  --create-namespace \
  -f core/traefik/helm-values.yaml

kubectl rollout status deployment traefik -n kube-system --timeout=180s

# -------------------------
# CERT MANAGER
# -------------------------
echo "=== INSTALL CERT-MANAGER ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

kubectl wait --for=condition=Available deployment \
  -n cert-manager --all --timeout=180s

echo "=== WAIT WEBHOOK ==="
sleep 20

# -------------------------
# ISSUER
# -------------------------
echo "=== APPLY ISSUER ==="
kubectl apply -f cert-manager/clusterissuer.yaml

sleep 10

# -------------------------
# APPS
# -------------------------
echo "=== DEPLOY APPS ==="

if [ -d "apps" ] && [ "$(ls -A apps 2>/dev/null)" ]; then
  kubectl apply -f apps/
else
  echo "No apps found, skipping deployment"
fi

echo "=== DONE 🚀 ==="