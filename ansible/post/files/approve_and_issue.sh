#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Approve and Issue CSRs for our generated Power Workers only

# Var: ${self.triggers.vpc_support_server_ip}
PROXY_SERVER="${1}"

# Var: ${self.triggers.counts}
POWER_COUNT="${2}"

# Var: ${self.triggers.approve}
POWER_PREFIX="${3}"

APPROVED_WORKERS=0
ISSUED_WORKERS=0

IDX=0
while [ "$IDX" -lt "121" ]
do
  export HTTPS_PROXY="http://${PROXY_SERVER}:3128"

  echo "Try number: ${IDX}"
  echo "List of Power Workers: "
  oc get nodes -l 'kubernetes.io/arch=ppc64le' -o json | jq -r '.items[] | .metadata.name'
  echo ""

  JSON_BODY=$(oc get csr -o json | jq -r '.items[] | select (.spec.username == "system:serviceaccount:openshift-machine-config-operator:node-bootstrapper")' | jq -r '. | select(.status == {})')
  for CSR_REQUEST in $(echo ${JSON_BODY} | jq -r '. | "\(.metadata.name),\(.spec.request)"')
  do 
    CSR_NAME=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $1}')
    CSR_REQU=$(echo ${CSR_REQUEST} | sed 's|,| |'| awk '{print $2}')
    echo "CSR_NAME: ${CSR_NAME}"
    NODE_NAME=$(echo ${CSR_REQU} | base64 -d | openssl req -text | grep 'Subject:' | awk '{print $NF}')
    echo "NODE_NAME: ${NODE_NAME}"

    if grep -q "system:node:${POWER_PREFIX}-worker-" <<< "$NODE_NAME"
    then
      echo ""
      echo "${CSR_NAME}" | xargs -r oc adm certificate approve
      APPROVED_WORKERS=$(($APPROVED_WORKERS + 1))
    fi
  done

  LOCAL_WORKER_SCAN=0
  while [ "$LOCAL_WORKER_SCAN" -lt "$POWER_COUNT" ]
  do
    # username: system:node:mac-674e-worker-0
    for CSR_NAME in $(oc get csr -o json | jq -r '.items[] | select (.spec.username == "'system:node:${POWER_PREFIX}-worker-${ISSUED_WORKERS}'")' | jq -r '.metadata.name')
    do
      # Dev note: will approve more than one matching csr
      echo "Approving: ${CSR_NAME} system:node:${POWER_PREFIX}-worker-${ISSUED_WORKERS}"
      echo "${CSR_NAME}" | xargs -r oc adm certificate approve
    done
    LOCAL_WORKER_SCAN=$(($LOCAL_WORKER_SCAN + 1))
  done

  if [ "${IDX}" -eq "240" ]
  then
    echo "Exceeded the wait time for CSRs to be generated - >120 minutes"
    exit -1
  fi

  NODE_COUNT=0
  STOP_SEARCH=""
  while [ "$NODE_COUNT" -lt "$POWER_COUNT" ]
  do
    EXISTS=$(oc get nodes -l kubernetes.io/arch=ppc64le -o json | \
      jq -r '.items[].metadata.name' | \
      grep "${POWER_PREFIX}-worker-${ISSUED_WORKERS}")
    if [ -z "${EXISTS}" ]
    then
      echo "Haven't found worker yet: ${POWER_PREFIX}-worker-${ISSUED_WORKERS}"
      STOP_SEARCH="NOT_FOUND"
      break
    fi
    NODE_COUNT=$(($NODE_COUNT + 1))
  done

  if [ -z "${STOP_SEARCH}" ]
  then
    # Checks if the nodes are READY
    INTER_COUNT=$(oc get nodes -owide | grep ppc64le | grep Ready | wc -l)
    if [ "${INTER_COUNT}" == "${POWER_COUNT}" ]
    then
      IDX=1000
      echo "Nodes are ready"
    else
      echo "Nodes are NOT ready"
      oc get nodes -owide
      oc get csr
    fi
  else 
    # 30 second sleep
    echo "waiting for the csrs"
    sleep 30
  fi
  IDX=$(($IDX + 1))
done

READY_COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep Ready | wc -l)
while [ "$NODE_COUNT" -ne "$POWER_COUNT" ]
do
  oc get csr | grep 'kubernetes.io/kubelet-serving' \
    | grep 'Pending' | awk '{print $1}' \
    | xargs -r oc adm certificate approve
  sleep 30
done