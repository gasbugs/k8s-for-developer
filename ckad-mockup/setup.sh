#!/bin/bash
set -e

echo "1. Creating Kind Cluster..."
kind create cluster --config kind-mockup-config.yaml

echo "2. Installing Cilium..."
cilium install --version 1.18.4

echo "3. Installing Traefik..."
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik --namespace traefik --create-namespace --values traefik-values.yaml

echo "4. Setting up Lab Environment..."
bash setup-lab.sh

echo "Setup Complete!"
