#!/bin/bash
if [[ -n "$1" ]]; then
  imageTag=$1
else
  imageTag="latest"
fi
helm install osgp-platform . -f values.yaml --set "imageTag=${imageTag}"
