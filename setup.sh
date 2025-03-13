#!/bin/bash
installDevTools=$1
if [[ ! $(type -P "k3d") ]]; then
  # Download k3d
  echo Installing k3d
  wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

pvpath=/tmp/k3dvolume
mkdir -p $pvpath

if [[ -n "$installDevTools" ]]; then
  createRegistry="--registry-create test-registry"
fi
# Create k3s cluster and registry with k3d
k3d cluster create test \
  $createRegistry \
  --volume $pvpath:/k3d/pv

if [[ -n "$installDevTools" ]]; then
  echo "Installing Kubernetes dashboard & PGWeb"
  # Add kubernetes-dashboard repository
  helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
  # Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
  helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
  # Setting kubernetes dashboard yamls
  kubectl apply -R -f charts/dev/kubernetes-dashboard/
  kubectl apply -R -f charts/dev/pgweb/
  # Get correct port for test registry, this port is needed to push local images
  docker ps -f name=test-registry
fi
