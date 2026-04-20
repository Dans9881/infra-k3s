#!/bin/bash

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f values.yaml