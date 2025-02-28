#!/bin/bash
POD_NAME=$(kubectl get pods -l=app=activemq -o name | cut -d '/' -f 2)

rm -rf cucumber-output
kubectl cp ${POD_NAME}:/target/output cucumber-output

mvn verify
