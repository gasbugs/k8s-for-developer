#!/bin/bash
set -e

echo "1. Creating Kind Cluster..."
if kind get clusters | grep -q "ckad-mockup"; then
  echo "Cluster 'ckad-mockup' already exists. Skipping creation."
else
  kind create cluster --config kind-mockup-config.yaml
fi

echo "2. Installing Cilium..."
# Ignore error if already installed
cilium install --version 1.18.4 || echo "Cilium installation step skipped (likely already installed)"

echo "Installing Rancher Local Path Provisioner..."
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml

echo "3. Installing Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
# Use upgrade --install for idempotency
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml

echo "4. Setting up Lab Environment..."
bash setup-lab.sh

echo "Setup Complete!"
