#!/bin/bash
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

echo "Setting up Kind cluster ckad-mockup-2..."
kind create cluster --name ckad-mockup-2 --config kind-config.yaml
