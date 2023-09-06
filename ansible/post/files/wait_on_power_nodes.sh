#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# The code waits for the CSRs to match

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

# Var: ${self.triggers.counts}
POWER_COUNT="${2}"

IDX=0
while [ "$IDX" -lt "121" ]
do
    export HTTPS_PROXY="http://${PROXY_SERVER}:3128"

    echo "Try number: ${IDX}"
    echo "List of Power Workers: "
    oc get nodes -l 'kubernetes.io/arch=ppc64le' -o json | jq -r '.items[] | .metadata.name'
    echo ""

    echo "CSRs reported back are: "
    oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name'

    echo "Check Cluster Operators: ${IDX}"
    ACTUAL_COUNT=$(oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | wc -l)
    if [ "${ACTUAL_COUNT}" -eq "${POWER_COUNT}" ]
    then
      break
    fi

    if [ "${IDX}" -eq "120" ]
    then
      echo "Exceeded the wait time for cluster operators - >120 minutes"
    fi

    # Wait for a minute
    echo "waiting for the csrs to match ${ACTUAL_COUNT} to equal ${POWER_COUNT}"
    sleep 60
    IDX=$(($IDX + 1))
done