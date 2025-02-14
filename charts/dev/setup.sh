#!/bin/bash
# Download k3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
# Create k3s cluster and registry with k3d
k3d cluster create test --registry-create test-registry
# Start the created cluster
k3d cluster start test
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
# Get correct port for test registry, this port is needed to push local images
docker ps -f name=test-registry
# Setting kubernetes dashboard yamls
kubectl apply -R -f kubernetes-dashboard/
