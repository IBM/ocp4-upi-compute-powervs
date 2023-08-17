#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count}
COUNT="${3}"

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${2}"

IDX=0
while [ "$IDX" -lt "$COUNT" ]
do
    echo "Removing the taint for Worker: ${NAME_PREFIX}-worker-${IDX}"
    export HTTPS_PROXY="http://${PROXY_SERVER}:3128"
    oc adm taint node ${NAME_PREFIX}-worker-${IDX} node.cloudprovider.kubernetes.io/uninitialized- \
        || true
    IDX=$(($IDX + 1))
done