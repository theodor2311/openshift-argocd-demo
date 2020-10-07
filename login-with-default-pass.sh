#!/bin/bash
ARGOCD_SERVER=$(oc -n argocd get route argocd-server -o jsonpath='{.spec.host}')
ARGOCD_SERVER_PASSWORD=$(oc -n argocd get secret argocd-cluster -ojsonpath='{.data.admin\.password}' | base64 -d)
argocd --insecure --grpc-web login "${ARGOCD_SERVER}:443" --username admin --password "${ARGOCD_SERVER_PASSWORD}"
