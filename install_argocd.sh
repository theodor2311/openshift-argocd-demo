#!/bin/bash
set -euoE pipefail
echo 'Creating ArgoCD project...'
oc new-project argocd >/dev/null

OPERATOR_NAME=argocd-operator

echo 'Installing ArgoCD Operator...'
oc create -f - >/dev/null << EOF
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: ${OPERATOR_NAME}
  namespace: argocd
spec:
  targetNamespaces:
    - argocd
EOF

oc create -f - >/dev/null << EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${OPERATOR_NAME}
  namespace: argocd
spec:
  channel: "$(oc get packagemanifest ${OPERATOR_NAME} -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')"
  installPlanApproval: Automatic
  name: ${OPERATOR_NAME}
  source: "$(oc get packagemanifest ${OPERATOR_NAME} -n openshift-marketplace -o jsonpath='{.status.catalogSource}')"
  sourceNamespace: "$(oc get packagemanifest ${OPERATOR_NAME} -n openshift-marketplace -o jsonpath='{.status.catalogSourceNamespace}')"
  startingCSV: "$(oc get packagemanifest ${OPERATOR_NAME} -n openshift-marketplace -o jsonpath="{.status.channels[?(@.name==\"$(oc get packagemanifest ${OPERATOR_NAME} -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')\")].currentCSV}")"
EOF

sleep 10

oc rollout status deployment/argocd-operator -n argocd > /dev/null

echo 'ArgoCD Operator Installed.'
echo 'Creating ArgoCD Instance...'

oc create -f - > /dev/null <<EOF
apiVersion: argoproj.io/v1alpha1
kind: ArgoCD
metadata:
  name: argocd
  namespace: argocd
spec:
  server:
    route:
      enabled: true
  dex:
    image: quay.io/redhat-cop/dex
    version: v2.22.0-openshift
    openShiftOAuth: true
  rbac:
    policy: |
      g, system:cluster-admins, role:admin
EOF

sleep 20

echo 'Waiting for ArgoCD server startup...'
oc rollout status deployment/argocd-server -n argocd > /dev/null

echo 'ArgoCD installation completed.'

ARGOCD_SERVER_PASSWORD=$(oc get secret argocd-cluster -ojsonpath='{.data.admin\.password}' | base64 -d)
ARGOCD_SERVER=$(oc -n argocd get route argocd-server -o jsonpath='{.spec.host}')

echo "You can access the ArgoCD from:"
echo "https://${ARGOCD_SERVER}"
echo "Local Admin Password:"
echo "${ARGOCD_SERVER_PASSWORD}"