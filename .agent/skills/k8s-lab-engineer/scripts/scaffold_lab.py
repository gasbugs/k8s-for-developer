#!/usr/bin/env python3
import os
import sys
import argparse

SETUP_TEMPLATE = """#!/bin/bash
set -e

# Container engine detection
if docker info >/dev/null 2>&1; then
    CONTAINER_ENGINE="docker"
elif podman info >/dev/null 2>&1; then
    CONTAINER_ENGINE="podman"
else
    echo "Error: Neither Docker nor Podman found."
    exit 1
fi

echo "Setting up Kind cluster {name}..."
kind create cluster --name {name} --config kind-config.yaml
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
nodes:
- role: control-plane
- role: worker
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
        "kind-config.yaml": KIND_CONFIG_TEMPLATE,
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
