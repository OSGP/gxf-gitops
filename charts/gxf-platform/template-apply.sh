#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "$1" ]]; then
  imageTag=$1
else
  imageTag="latest"
fi
helm install osgp-platform "$DIR" -f "$DIR/values.yaml" --set "imageTag=${imageTag}"
