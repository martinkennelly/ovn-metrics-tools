#!/bin/bash
set -eo pipefail
# first argument can be directory to store outputs
# iterate through OVN master leader,a node pod and grab the metrics
# tested with OCP 4.10

OVN_NAMESPACE="${OVN_NAMESPACE:-openshift-ovn-kubernetes}"

[ ! -z "$1" ] && dir="$1" && [ ! -d "$dir" ] && echo "creating directory '$dir'" && mkdir -p "$dir"
[ -z "$1" ] && dir=$(mktemp -d) && echo "output directory: '$dir'"

leader_host="$(kubectl get cm -n openshift-ovn-kubernetes ovn-kubernetes-master -o jsonpath='{.metadata.annotations.control-plane\.alpha\.kubernetes\.io\/leader}' | jq '.holderIdentity' | cut -c2- | rev | cut -c2- |rev)"
master_leader_pod="$(kubectl get pods -n $OVN_NAMESPACE --field-selector spec.nodeName=$leader_host -l app=ovnkube-master -o=jsonpath='{.items..metadata.name}')"
kubectl -n "$OVN_NAMESPACE" exec "$master_leader_pod" -c ovnkube-master curl "127.0.0.1:29102/metrics" > "$dir/$master_leader_pod-29102"
node_pod="$(kubectl get pods -n $OVN_NAMESPACE --field-selector spec.nodeName=$leader_host -l app=ovnkube-node -o=jsonpath='{.items..metadata.name}')"
kubectl -n "$OVN_NAMESPACE" exec "$node_pod" -c ovnkube-node curl "127.0.0.1:29103/metrics" > "$dir/$node_pod-29103"
