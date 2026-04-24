#!/bin/bash
set -e

echo "=== START GITHUB RUNNER ==="

read -p "Repo URL: " REPO_URL
read -p "Runner Name: " RUNNER_NAME
read -p "Runner Token: " RUNNER_TOKEN

docker rm -f github-runner 2>/dev/null || true

docker run -d \
  --name github-runner \
  --restart always \
  -e RUNNER_NAME=${RUNNER_NAME} \
  -e RUNNER_REPO_URL=${REPO_URL} \
  -e RUNNER_TOKEN=${RUNNER_TOKEN} \
  -e RUNNER_WORKDIR=/tmp/runner \
  --cpus="1" \
  --memory="2g" \
  --read-only \
  --tmpfs /tmp \
  --security-opt no-new-privileges \
  ghcr.io/actions/actions-runner:latest

echo "=== RUNNER STARTED ==="