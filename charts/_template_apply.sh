#!/bin/bash
# Common part of helm template script

working_dir=$1
helm_name=$2
image_tag=$3

if [[ $(kubectl config current-context) != "k3d-test" ]]; then
  echo You are not in the k3d-test context, refusing to install helm scripts
  exit 1
fi

if [[ -z "$image_tag" ]]; then
  image_tag="latest"
fi

if [[ $(helm get metadata $helm_name) ]]; then
  verb=upgrade
else
  verb=install
fi

echo Performing $verb of $helm_name from $working_dir with tag $image_tag

helm $verb $helm_name "$working_dir" -f "$working_dir/values.yaml" --set "imageTag=${image_tag}"
