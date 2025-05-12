# gxf-gitops
Gitops repo for GXF platform

## Dependencies
- You need an openssl version that can generate ed25519
- You need bash4
- You need java8
- User has access to docker

for Mac: 
- `brew install libfido2`
- `brew install bash`
- `brew install kubectl`
- Install Helm: `brew install helm`
- Install k3d: `brew install k3d`
- Install Docker desktop

for Linux:
- `sudo apt install openjdk-8-jre-headless`
- `sudo apt install docker`
- `sudo apt install kubectl`
- `sudo apt install helm`
- Add user to docker group: `usermod -aG docker paulus`

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

