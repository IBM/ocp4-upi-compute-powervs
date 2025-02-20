#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count} [This is removed OCTOPUS-679]
#COUNT="${1}"

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${2}"

# Get COUNT for all power workers with name having NAME_PREFIX 
# Nodes that are NotReady are included in the count intentionally
COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep "${NAME_PREFIX}" | grep -c Ready)
echo "Available COUNT for Power worker/s with Prefix '${NAME_PREFIX}' is ${COUNT}"

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the Worker: ${NAME_PREFIX}-worker-${IDX}"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
    IDX=$(($IDX + 1))
done
