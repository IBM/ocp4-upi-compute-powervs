#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

echo "Worker Status is: "
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{","}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
echo "Cluster Operator is: "
oc get co

IDX=0
while [ "$IDX" -lt "121" ]
do
    export HTTPS_PROXY="http://${PROXY_SERVER}:3128"
    echo "Check Cluster Operators: ${IDX}"
    FAL_COUNT=$(oc get co -o jsonpath='{range .items[*]}{.metadata.name}{","}{.status.conditions[?(@.type=="Available")].status}{"\n"}{end}' | grep False | wc -l)
    if [ "${FAL_COUNT}" -eq "0" ]
    then
      break
    fi

    if [ "${IDX}" -eq "120" ]
    then
      echo "Exceeded the wait time for cluster operators - >120 minutes"
      exit 3
    fi

    oc get co -o yaml
    echo "waiting for the cluster operators to return to operation"
    sleep 60
    IDX=$(($IDX + 1))
done