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
  # Get correct port for test registry, this port is needed to push local images
  echo "Your test registry port:"
  docker ps -f name=test-registry

  # Installing dev chart
  ./charts/dev/template-apply.sh
fi

kubectl cluster-info

./generate-secrets.sh
