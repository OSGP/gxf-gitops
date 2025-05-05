# gxf-gitops
Gitops repo for GXF platform

## Dependencies
You need an openssl version that can generate ed25519:

for Mac: `brew install libfido2`

## Installation
- Install k3d: `brew install k3d`
- Install Helm: `brew install helm`

### Setup local cluster
Be careful to use bash to execute setup.sh:

`bash setup.sh`

### Destroy local cluster
`k3d cluster delete test`

## Check status
### Get pods
kubectl get pods

### Get all events
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'

