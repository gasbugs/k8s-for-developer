#!/bin/bash
echo "Removing CKAD Mockup Environment (Kind Cluster: ckad-mockup)..."
kind delete cluster --name ckad-mockup
echo "Done."

echo "Removing Docker image and artifacts..."
docker rmi internal-tool:v2.0 2>/dev/null || true
rm -f tool-v2.tar
rm -f Dockerfile 2>/dev/null || true
rm -f /tmp/sidecar_error.log 2>/dev/null || sudo rm -f /tmp/sidecar_error.log || echo "Warning: Could not remove /tmp/sidecar_error.log"
