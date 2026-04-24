#!/bin/bash

echo "=== STOP RUNNER ==="

docker rm -f github-runner || true

echo "=== DONE ==="