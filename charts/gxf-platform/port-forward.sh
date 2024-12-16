# bin/bash
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 > port-forward.log 2>&1 &
kubectl port-forward svc/activemq 8161:8161 > port-forward.log 2>&1 &

