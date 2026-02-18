#!/bin/bash
set -e

# 컨테이너 엔진 감지
if docker info >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
elif podman info >/dev/null 2>&1; then
    CONTAINER_ENGINE="podman"
else
    echo "오류: Docker 또는 Podman을 찾을 수 없습니다. 하나를 설치해 주세요."
    exit 1
fi

echo "Removing CKAD Mockup Environment (Kind Cluster: ckad-mockup)..."
kind delete cluster --name ckad-mockup
echo "Done."

echo "Removing $CONTAINER_ENGINE image and artifacts..."
$CONTAINER_ENGINE rmi internal-tool:v2.0 2>/dev/null || true
rm -f tool-v2.tar
rm -f Dockerfile 2>/dev/null || true
rm -f old-deploy.yaml 2>/dev/null || true
rm -f /tmp/sidecar_error.log 2>/dev/null || sudo rm -f /tmp/sidecar_error.log || echo "Warning: Could not remove /tmp/sidecar_error.log"
