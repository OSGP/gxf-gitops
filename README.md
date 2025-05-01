# gxf-gitops
Gitops repo for GXF platform

## Installation
- Install k3d: `brew install k3d`
- Install Helm: `brew install helm`

### Setup local cluster
`bash setup.sh`

### Destroy local cluster
`k3d cluster delete test`

## Check status
### Get pods
kubectl get pods

### Get all events
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'