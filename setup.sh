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

# Check necesary tools
error=0
if ! command -v docker 2>&1 >/dev/null
then
    echo "Docker could not be found, please install"
    error=1
fi
if ! command -v keytool 2>&1 >/dev/null
then
    echo "Keytool could not be found, please install openjdk8"
    error=1
fi
if ! command -v kubectl 2>&1 >/dev/null
then
    echo "Kubectl could not be found, please install"
    error=1
fi

if [ $error -gt 0 ]; then
    echo "Some dependencies unmet, check README for installation instructions."
    exit 1
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

bash generate-secrets.sh
