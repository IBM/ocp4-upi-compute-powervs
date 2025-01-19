#!/usr/bin/env bash

################################################################
# Copyright 2023, 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Approve and Issue CSRs for our generated Power workers only

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

# Var: ${self.triggers.counts}
POWER_COUNT="${2}"

# Var: ${self.triggers.approve}
POWER_PREFIX="${3}"

# Machine Prefix
MACHINE_PREFIX="${POWER_PREFIX}-worker"

# Check count for Power worker/s to be added is not zero
if [ "${POWER_COUNT}" -eq "0" ]
then
  echo "No Power workers to approve."
  exit 0
fi

# Setting values for variables
IDX=0

READY_COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep "${MACHINE_PREFIX}" | grep -v NotReady | grep -c Ready)

# Approce CSR and Check Ready status
while [ "${READY_COUNT}" -ne "${POWER_COUNT}" ]
do
  
  echo "List of All Power Workers: "
  oc get nodes -l 'kubernetes.io/arch=ppc64le' -o json | jq -r '.items[] | .metadata.name'
  echo ""

  echo "Approve and Issue - #${IDX}"
  echo "List of Power Workers to be added with prefix '${POWER_PREFIX}': "
  oc get nodes -l 'kubernetes.io/arch=ppc64le' --no-headers=true | grep "${MACHINE_PREFIX}"
  echo ""

  # Approve openshift-machine-config-operator:node-bootstrapper CSR/s
  JSON_BODY=$(oc get csr -o json | jq -r '.items[] | select (.spec.username == "system:serviceaccount:openshift-machine-config-operator:node-bootstrapper")' | jq -r '. | select(.status == {})')
  for CSR_REQUEST in $(echo ${JSON_BODY} | jq -cr '. | "\(.metadata.name),\(.spec.request)"')
  do
    CSR_NAME=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $1}')
    CSR_REQU=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $2}')
    echo "CSR_NAME: ${CSR_NAME}"
    NODE_NAME=$(echo ${CSR_REQU} | base64 -d | openssl req -text | grep 'Subject:' | awk '{print $NF}')
    echo "Pending CSR found for NODE_NAME: ${NODE_NAME}"

    if grep -q "system:node:${MACHINE_PREFIX}-" <<< "$NODE_NAME"
    then
      oc adm certificate approve "${CSR_NAME}"      
    fi
  done

  # Approve system:node:${MACHINE_PREFIX} CSRs
  LOCAL_WORKER_SCAN=0
  while [ "$LOCAL_WORKER_SCAN" -lt "$POWER_COUNT" ]
  do
    # username: system:node:mac-674e-worker-0
    for CSR_NAME in $(oc get csr -o json | jq -r '.items[] | select (.spec.username == "'system:node:${MACHINE_PREFIX}-${LOCAL_WORKER_SCAN}'")' | jq -r '.metadata.name')
    do
      # Dev note: will approve more than one matching csr
      echo "Approving: ${CSR_NAME} system:node:${MACHINE_PREFIX}-${LOCAL_WORKER_SCAN}"
      oc adm certificate approve "${CSR_NAME}"
    done
    sleep 10
    LOCAL_WORKER_SCAN=$(($LOCAL_WORKER_SCAN + 1))
  done

  # Wait for 30 seconds before we hammer the system
  echo "Sleeping before re-running - 30 seconds"
  sleep 30

  # Re-read the 'Ready' count
  READY_COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep "${MACHINE_PREFIX}" | grep -v NotReady | grep -c Ready)

  # Increment counter
  IDX=$(($IDX + 1))

  # End Early... we've checked enough.
  if [ "${IDX}" -eq "60" ]
  then
    echo "Exceeded the wait time for CSRs to be generated and Worker/s node to be ready - > 30 minutes"
    echo "Printing all Nodes"
    oc get nodes -owide
    echo ""
    echo "Get All CSRs"
    oc get csr
    echo "Exiting with Error. Ready count - ${READY_COUNT} is not matching with expected Power Worker count - ${POWER_COUNT}"
    echo "Supplied Worker/s with prefix: '${MACHINE_PREFIX}' are not yet Ready."
    exit -1
  fi

done

# Final Check
if [ "${READY_COUNT}" -eq "${POWER_COUNT}" ]
then
  echo "Supplied Worker/s with prefix: '${MACHINE_PREFIX}' are Ready."
  oc get nodes -l 'kubernetes.io/arch=ppc64le' --no-headers=true | grep "${MACHINE_PREFIX}"
fi
