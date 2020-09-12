#!/bin/bash
set -e
ARGOCD_SERVER=$(oc -n argocd get route argocd-server -o jsonpath='{.spec.host}')

if [[ ! -z ${ARGOCD_SERVER} ]]; then
  echo "Downloading argocd cli from ${ARGOCD_SERVER}"
  curl -sSL -o /usr/local/bin/argocd https://${ARGOCD_SERVER}/download/argocd-linux-amd64 -k
  chmod +x /usr/local/bin/argocd
else
  VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" |
      grep '"tag_name":' |                                            
      sed -E 's/.*"([^"]+)".*/\1/')
  echo "Downloading argocd cli from github"
  curl -L https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64 -o /usr/local/bin/argocd
  chmod +x /usr/local/bin/argocd
fi

echo "ArgoCD CLI install completed."
argocd version --
