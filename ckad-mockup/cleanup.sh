#!/bin/bash
echo "Removing CKAD Mockup Environment (Kind Cluster: ckad-mockup)..."
kind delete cluster --name ckad-mockup
echo "Done."
