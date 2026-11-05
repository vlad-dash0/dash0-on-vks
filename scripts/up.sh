#!/usr/bin/env bash
# Install the Dash0 operator + a small demo app, sending data to Dash0.
# Needs .env with DASH0_ENDPOINT, DASH0_API_ENDPOINT, DASH0_TOKEN, DASH0_DATASET (see README).
# Local kind cluster by default; for VKS: KUBE_CONTEXT=<vks-context> scripts/up.sh
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a
CTX="${KUBE_CONTEXT:-kind-vks-rehearsal}"
k() { kubectl --context "$CTX" "$@"; }

if [ "$CTX" = kind-vks-rehearsal ] && ! kind get clusters | grep -qx vks-rehearsal; then
  (cd manifests/kind && kind create cluster --config cluster.yaml)
fi

# The collector needs hostPath + hostPort, which VKS's default "restricted" pod security blocks.
k create namespace dash0-system --dry-run=client -o yaml | k apply -f -
k label --overwrite ns dash0-system pod-security.kubernetes.io/enforce=privileged
k -n dash0-system create secret generic dash0-authorization-secret \
  --from-literal=token="$DASH0_TOKEN" --dry-run=client -o yaml | k apply -f -

helm repo add dash0-operator https://dash0hq.github.io/dash0-operator >/dev/null 2>&1 || true
helm repo update dash0-operator >/dev/null
helm --kube-context "$CTX" upgrade --install dash0-operator dash0-operator/dash0-operator -n dash0-system --wait \
  --set operator.clusterName="${CLUSTER_NAME:-$CTX}" \
  --set operator.dash0Export.enabled=true \
  --set operator.dash0Export.endpoint="$DASH0_ENDPOINT" \
  --set operator.dash0Export.apiEndpoint="$DASH0_API_ENDPOINT" \
  --set operator.dash0Export.dataset="${DASH0_DATASET:-default}" \
  --set operator.dash0Export.secretRef.name=dash0-authorization-secret \
  --set operator.dash0Export.secretRef.key=token \
  --set operator.instrumentation.enablePythonAutoInstrumentation=true

k apply -f manifests/demo-app.yaml -f manifests/monitoring.yaml
k -n demo rollout status deploy --timeout=300s
k get pods -n dash0-system -o wide
echo "Done. In Dash0, filter on k8s.cluster.name=${CLUSTER_NAME:-$CTX} (namespace demo)."
