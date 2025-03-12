#!/bin/bash
if [[ -n "$1" ]]; then
  imageTag=$1
else
  imageTag="latest"
fi
helm install osgp-cucumber . -f values.yaml --set "imageTag=${imageTag}"
