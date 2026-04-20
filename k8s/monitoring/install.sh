#!/bin/bash
set -e

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace \
  -f values.yaml

kubectl rollout status deployment/monitoring-grafana -n monitoring

kubectl apply -f grafana-ingress.yaml