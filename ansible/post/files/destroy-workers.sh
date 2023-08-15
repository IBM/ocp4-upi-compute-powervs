#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.count}
COUNT="${1}"

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${2}"

# Var: self.triggers.name_prefix
NAME_PREFIX="${3}"

for IDX in $(seq 0 ${COUNT})
do
    echo "Removing the Worker: ${NAME_PREFIX}-worker-${IDX}"
    export HTTPS_PROXY="http://${PROXY_SERVER}:3128"
    oc delete node ${NAME_PREFIX}-worker-${IDX} || true
done