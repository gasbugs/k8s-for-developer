#!/bin/bash
set -e

# 컨테이너 엔진 감지 및 설정
if docker info >/dev/null 2>&1; then
    echo "Docker가 감지되었습니다. Docker를 사용하여 진행합니다."
elif command -v podman >/dev/null 2>&1; then
    echo "Docker를 찾을 수 없으나 Podman이 감지되었습니다. Podman 설정을 시작합니다..."
    
    if ! podman machine ls --format '{{.Name}}' | grep -q "podman-machine-default"; then
        echo "Podman 머신을 초기화합니다 (2 CPUs, 6GB RAM)..."
        podman machine init --cpus 2 --memory 6144 
        podman machine set --rootful
    fi
    
    if ! podman machine ls --format '{{.LastUp}}' | grep -q "Currently running"; then
        echo "Podman 머신을 시작합니다..."
        podman machine start
    fi
    
    export KIND_EXPERIMENTAL_PROVIDER=podman
else
    echo "오류: Docker 또는 Podman을 찾을 수 없습니다. 하나를 설치해 주세요."
    exit 1
fi

echo "1. Creating Kind Cluster ckad-mockup-2..."
if kind get clusters | grep -q "ckad-mockup-2"; then
  echo "Cluster 'ckad-mockup-2' already exists. Skipping creation."
else
  kind create cluster --name ckad-mockup-2 --config kind-config.yaml
fi

echo "2. Installing Cilium..."
cilium install --version 1.18.4 || echo "Cilium installation step skipped (likely already installed)"

echo "3. Installing Rancher Local Path Provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml

echo "4. Installing Traefik via Helm..."
helm repo add traefik https://traefik.github.io/charts --force-update
helm repo update
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml

echo "5. Setting up Lab Environment..."
bash deploy-problems.sh

echo "Setup Complete!"
