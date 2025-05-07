# gxf-gitops
Gitops repo for GXF platform

## Dependencies
- You need an openssl version that can generate ed25519
- You need bash4

for Mac: 
- `brew install libfido2`
- `brew install bash`

## Installation
- Install k3d: `brew install k3d`
- Install Helm: `brew install helm`

### Setup local cluster
`bash setup.sh`

To also install dev tools (kubernetes dashboard):
`bash setup.sh 1`

### Destroy local cluster
`k3d cluster delete test`

## Check status
### Get pods
kubectl get pods

### Get all events
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'

