#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.nfs_deployment}
NFS_DEPLOYMENT="${1}"

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${2}"

# Var: self.triggers.nfs_namespace
NFS_NAMESPACE="${3}"

echo "Removing the Deployment for the NFS storage class. Please ensure that you have taken backup of NFS server."
export HTTPS_PROXY="http://${PROXY_SERVER}:3128"
oc delete deployment ${NFS_DEPLOYMENT} -n ${NFS_NAMESPACE}
