#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(dirname -- "$DIR")"

echo "Installing Kubernetes dashboard & PGWeb"
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

"$CHART_DIR"/_template_apply.sh --workingDir "$DIR" --helmName dev "$@"

echo "Kubernetes dashboard token: "
kubectl -n kubernetes-dashboard create token admin-user

"$DIR"/port-forward.sh
