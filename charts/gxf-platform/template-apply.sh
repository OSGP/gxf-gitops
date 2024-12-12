# bin/bash
helm template . -f values.yaml > helm-template.yaml && yamllint helm-template.yaml && kubectl apply -f helm-template.yaml