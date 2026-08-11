#!/bin/bash

# ################################################################
# Setup pre-requisites:
# 1. Routing Table ibm_is_vpc_routing_table_route delegate_vpc next_hop 0.0.0.0
# 2. Security Group Access is setup
# 3. Setup OpenShift Pre-Req
#    - DNS pinned
#    - Storage
#    - imagepruner
#    - ingresscontroller
#    - routingViaHost

resource "ibm_is_vpc_routing_table_route" "route_to_powervs" {
  vpc           = var.vpc
  routing_table = var.routing_table
  zone          = var.zone
  name          = "powervs-route-1"
  destination   = var.destination
  action        = "delegate_vpc"
  next_hop      = "0.0.0.0"
}








echo "[OPENSHIFT] All Storage Needs to Run on Intel"
oc annotate --kubeconfig /root/.kube/config ns openshift-cluster-csi-drivers \
    scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=amd64

echo "[OPENSHIFT] Run DNS Operator on Intel Only"
oc patch dns.operator/default -p \
    '{ "spec" : {"nodePlacement": {"nodeSelector": {"kubernetes.io/arch" : "amd64"}}}}' \
    --type merge

echo "[OPENSHIFT] Run imagepruner only on Intel"
oc patch imagepruner/cluster -p '{ "spec" : {"nodeSelector": {"kubernetes.io/arch" : "amd64"}}}' \
    --type merge

echo "[OPENSHIFT] Run ingresscontroller only on Intel"
oc patch ingresscontroller/default \
    -n openshift-ingress-operator \
    -p '{ "spec": { "nodePlacement": { "nodeSelector": { "matchLabels": { "kubernetes.io/arch": "amd64" }}}}}' \
    --type merge

echo "[OPENSHIFT] Setup Routing via Host"
oc patch network.operator/cluster --type merge -p \
  '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"routingViaHost":true}}}}}'


# Add to the security groups on the commandline

# Add the Transit Gateway Connections to VPC

# Setup Storage Tests





  


# Put Ingress only on intel workers

oc extract -n openshift-machine-api secret/master-user-data --keys=userData --to=- \
    > /tmp/worker.ign


# Use Existing Key (confirm it exists on PVS/VPC)