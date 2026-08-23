#!/bin/bash

# ################################################################
# Setup pre-requisites:
# 1. Routing Table ibm_is_vpc_routing_table_route delegate_vpc next_hop 0.0.0.0
# 2. Storage, Security Group Access is setup
# 3. Setup OpenShift Pre-Req
#    - DNS pinned
#    - Storage
#    - imagepruner
#    - ingresscontroller
#    - routingViaHost
# 4. Grab the Ignition File for the Environment

#####################################################
# 1. Routing Table ibm_is_vpc_routing_table_route delegate_vpc next_hop 0.0.0.0

# TODO: CONVERT TO `ibmcloud cli call`
# resource "ibm_is_vpc_routing_table_route" "route_to_powervs" {
#   vpc           = var.vpc
#   routing_table = var.routing_table
#   zone          = var.zone
#   name          = "powervs-route-1"
#   destination   = var.destination
#   action        = "delegate_vpc"
#   next_hop      = "0.0.0.0"
# }

#####################################################
# 2. Other Setup

# TODO: Setup Storage Tests
# Add NFS Server on Intel Side 
# This is *LAST* thing to add

# TODO: Add to the security groups on the commandline
# May need to get details from prior commits

# TODO: Add the Transit Gateway Connections to VPC
# Previously done in terraform, need to extract to this location.

# TODO: Use Existing Key (confirm it exists on PVS/VPC)
# If it doesn't error out and alert the user

#####################################################
# 3. Setup OpenShift Pre-Req

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

#####################################################
# 4. Grab the Ignition File for the Environment

oc extract -n openshift-machine-api secret/master-user-data --keys=userData --to=- > /tmp/worker.ign
