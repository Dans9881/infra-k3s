#!/bin/bash
set -euo pipefail

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "=== INSTALL TRAEFIK ==="
helm repo add traefik https://traefik.github.io/charts || true
helm repo update

helm upgrade --install traefik traefik/traefik \
  -n kube-system \
  --create-namespace \
  -f k8s/core/traefik/helm-values.yaml

echo "=== WAIT TRAEFIK READY ==="
kubectl rollout status deployment traefik -n kube-system --timeout=180s

# -------------------------
# CERT-MANAGER
# -------------------------
echo "=== INSTALL CERT-MANAGER ==="
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "=== WAIT CERT-MANAGER DEPLOYMENTS ==="
kubectl wait --for=condition=Available deployment \
  -n cert-manager --all --timeout=180s

# 🔥 FIX RACE CONDITION (INI YANG TADI NGEBUNUH LO)
echo "=== WAIT CERT-MANAGER WEBHOOK ==="

for i in {1..30}; do
  if kubectl get pods -n cert-manager | grep cert-manager-webhook | grep Running >/dev/null 2>&1; then
    echo "Webhook is running ✅"
    break
  fi

  echo "Waiting webhook ($i)..."
  sleep 5
done

# extra buffer biar admission controller bener2 ready
sleep 15

# -------------------------
# CLUSTER ISSUER (WITH RETRY 🔥)
# -------------------------
echo "=== APPLY CLUSTER ISSUER ==="

for i in {1..5}; do
  if kubectl apply -f k8s/cert-manager/clusterissuer.yaml; then
    echo "ClusterIssuer applied ✅"
    break
  fi

  echo "Retry apply ClusterIssuer ($i)..."
  sleep 10
done

# -------------------------
# DEPLOY APPS
# -------------------------
echo "=== DEPLOY APPS ==="
kubectl apply -f k8s/apps/

# -------------------------
# WAIT CERTIFICATE (ANTI 404 HTTPS)
# -------------------------
echo "=== WAIT CERTIFICATE READY ==="

for i in {1..30}; do
  READY=$(kubectl get certificate -o jsonpath='{.items[0].status.conditions[0].status}' 2>/dev/null || echo "False")

  if [ "$READY" = "True" ]; then
    echo "✅ CERT READY"
    break
  fi

  echo "Waiting cert ($i)..."
  sleep 10
done

echo "=== DONE 🚀 ==="