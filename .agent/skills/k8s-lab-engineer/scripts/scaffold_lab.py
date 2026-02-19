#!/usr/bin/env python3
import os
import sys
import argparse

SETUP_TEMPLATE = """#!/bin/bash
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

echo "1. Creating Kind Cluster {name}..."
if kind get clusters | grep -q "{name}"; then
  echo "Cluster '{name}' already exists. Skipping creation."
else
  kind create cluster --name {name} --config kind-config.yaml
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
"""

SCORE_TEMPLATE = """#!/bin/bash
set -e

SCORE=0
TOTAL_SCORE=0
PASS_THRESHOLD=66

echo "=================================================="
echo "       {name} Scoring Script"
echo "=================================================="
echo ""

check_problem() {{
    local num=$1 pts=$2 desc=$3 cmd=$4
    echo -n "[Problem $num] $desc ($pts pts)... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS"
        SCORE=$((SCORE + pts))
    else
        echo "FAIL"
    fi
    TOTAL_SCORE=$((TOTAL_SCORE + pts))
}}

# Example Problem
# check_problem 1 10 "Verify Nginx Pod" "kubectl get pods | grep -q nginx"

echo ""
echo "=================================================="
echo "Final Score: $SCORE / $TOTAL_SCORE"
echo "=================================================="
"""

KIND_CONFIG_TEMPLATE = """kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: {name}
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 31080
    hostPort: 31080
    protocol: TCP
  - containerPort: 31443
    hostPort: 31443
    protocol: TCP
- role: worker
- role: worker
networking:
  disableDefaultCNI: true
"""

TRAEFIK_VALUES_TEMPLATE = """# 네트워크 포트 및 엔트리포인트 구성
# 엔트리포인트는 들어오는 트래픽을 위한 네트워크 리스너입니다.
ports:
  # 'web'이라는 이름의 HTTP 엔트리포인트 정의
  web:
    port: 80
    nodePort: 31080
    # 주석 해제하여 HTTP에서 HTTPS로 리다이렉트 활성화 가능
    # http:
    #   redirections:
    #     entryPoint:
    #       to: websecure
    #       scheme: https
    #       permanent: true

  # 'websecure'라는 이름의 HTTPS 엔트리포인트 정의
  websecure:
    port: 443
    nodePort: 31443

# 대시보드 및 API 설정 (실무에서는 보안 설정 필수)
api:
  dashboard: true
  insecure: true

# IngressClass 활성화 (기본값으로 설정하여 실습 편의성 증대)
ingressClass:
  enabled: true
  isDefaultClass: true

# Kubernetes 프로바이더 활성화 (Ingress 및 Gateway API)
providers:
  kubernetesIngress:
    enabled: true
  kubernetesGateway:
    enabled: true

# Gateway API 전용 리스너 구성 (포트 불일치 오류 방지용)
gateway:
  listeners:
    web:
      port: 80
      protocol: HTTP
      namespacePolicy:
        from: All
    websecure:
      port: 443
      protocol: HTTPS
      namespacePolicy:
        from: All

# 관측성(Observability) 및 로깅 설정
logs:
  general:
    level: INFO
  access:
    enabled: true
"""

CLEANUP_TEMPLATE = """#!/bin/bash
kind delete cluster --name {name}
"""

DEPLOY_TEMPLATE = """#!/bin/bash
set -e
echo "Deploying base resources for {name}..."
# kubectl apply -f ...
"""

def scaffold(output_dir, project_name):
    os.makedirs(output_dir, exist_ok=True)
    
    files = {
        "setup.sh": SETUP_TEMPLATE.format(name=project_name),
        "score.sh": SCORE_TEMPLATE.format(name=project_name),
        "cleanup.sh": CLEANUP_TEMPLATE.format(name=project_name),
        "deploy-problems.sh": DEPLOY_TEMPLATE.format(name=project_name),
        "kind-config.yaml": KIND_CONFIG_TEMPLATE.format(name=project_name),
        "traefik-values.yaml": TRAEFIK_VALUES_TEMPLATE,
        "problems.md": f"# {project_name} Tasks\\n\\n1. Solution task 1...",
        "solutions.md": f"# {project_name} Solutions\\n\\n1. How to solve task 1..."
    }
    
    for filename, content in files.items():
        path = os.path.join(output_dir, filename)
        with open(path, "w") as f:
            f.write(content)
        if filename.endswith(".sh"):
            os.chmod(path, 0o755)
            
    print(f"Scaffolded project '{project_name}' in {output_dir}")

def main():
    parser = argparse.ArgumentParser(description="Scaffold a K8s Lab project.")
    parser.add_argument("--output-dir", required=True, help="Directory to scaffold in")
    parser.add_argument("--name", default="k8s-lab", help="Project name")
    
    args = parser.parse_args()
    scaffold(args.output_dir, args.name)

if __name__ == "__main__":
    main()
