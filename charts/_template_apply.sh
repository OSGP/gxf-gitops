#!/bin/bash
# Common part of helm template script

workingDir=""
helmName=""
imageTag="latest"
valuesFile="values.yaml"

if ! command -v helm 2>&1 >/dev/null
then
    echo "Helm could not be found, please install"
    exit 1
fi

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --workingDir)
      workingDir="$2"
      shift 2
      ;;
    --helmName)
      helmName="$2"
      shift 2
      ;;
    --imageTag)
      imageTag="$2"
      shift 2
      ;;
    --valuesFile)
      valuesFile="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
done

if [ -z "${valuesFile}" ]; then
  echo "No values file given while applying template."
  exit 1
fi

if ! [ -f "$workingDir/$valuesFile" ]; then
  echo "Could not find given values file: $valuesFile"
  exit 1
fi

if [[ $(kubectl config current-context) != "k3d-test" ]]; then
  echo You are not in the k3d-test context, refusing to install helm scripts
  exit 1
fi


if [[ $(helm get manifest $helmName) ]]; then
  verb=upgrade
else
  verb=install
fi

echo Performing $verb of $helmName from $workingDir with tag $imageTag and values file $valuesFile

helm --debug $verb $helmName "$workingDir" -f "$workingDir/$valuesFile" --set "imageTag=${imageTag}"
