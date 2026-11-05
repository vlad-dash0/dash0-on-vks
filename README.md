# Dash0 operator on VMware VKS

Install the [Dash0 operator](https://github.com/dash0hq/dash0-operator) on a VMware vSphere Kubernetes Service
(VKS) cluster, deploy a small demo app, and check that its logs, metrics, traces and Kubernetes events arrive in Dash0.

## Run
Create `.env` (gitignored; never commit it) with your Dash0 organization's values: endpoints from
Settings → Endpoints, token from Settings → Auth Tokens.
```
DASH0_ENDPOINT=ingress.<region>.aws.dash0.com:4317
DASH0_API_ENDPOINT=https://api.<region>.aws.dash0.com
DASH0_TOKEN=auth_...
DASH0_DATASET=<dataset id, not display name>
```
Requires `kubectl` and `helm`.
```sh
KUBE_CONTEXT=<vks-context> CLUSTER_NAME=<name> scripts/up.sh   # a VKS cluster
scripts/up.sh                                                   # local kind cluster with VKS-style pod security
scripts/down.sh                                                 # delete the local kind cluster
```
Then, in Dash0, filter on `k8s.cluster.name=<name>` and look at the `demo` namespace.

## Notes
- VKS enforces the "restricted" Pod Security Standard. The operator's node collector needs hostPath and hostPort,
  so its namespace (`dash0-system`) must be labelled `privileged` first; otherwise the collector DaemonSet silently
  runs 0 pods. `up.sh` applies the label.
- Application namespaces can stay `restricted`; auto-instrumentation still works.
- Kubernetes events from the first ~90 s after monitoring is enabled are not captured.

To remove the operator: `helm uninstall dash0-operator -n dash0-system`.
