#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-Libmcloudense-Identifier: Apache-2.0
################################################################

# Report the straggler workspaces with tag 'mac-power-worker'
EXTRA_CRNS=$(ibmcloud resource search "tags:\"mac-power-worker\"" --output json | jq -r '.items[].crn')
echo "Checking the Straggler Workspaces: "
echo "${EXTRA_CRNS}"
for T_CRN in ${EXTRA_CRNS//'\n'/ }
do
  echo "-Straggler Workspace: ${T_CRN}"
  ibmcloud pi workspace target "${T_CRN}"

  echo "-- Cloud Connection --"
  ibmcloud pi cloud-connection list --json | jq -r '.cloudConnections[] | .name,.cloudConnectionID' || true

  echo "-- Network --"
  ibmcloud pi subnet list

  # Rare case when no volumes or instances are ever created in the workspace.
  echo "-- Volumes --"
  ibmcloud pi volume list || true

  echo "-- Instances --"
  ibmcloud pi instance list || true

  COUNT_INS=$(ibmcloud pi instance list --json | jq -r '.pvmInstances[].name' | wc -l)
  COUNT_NETS=$(ibmcloud pi subnet list --json | jq -r '.networks[].name' | wc -l)
  TOTAL=$((COUNT_INS + COUNT_NETS))

  echo "TOTAL RESOURCES: ${TOTAL}"
  RESOURCE_GROUP=$(cat "${SHARED_DIR}/RESOURCE_GROUP")
  echo 'ibmcloud resource service-instance-delete "${T_CRN}" -g "${RESOURCE_GROUP}" --force --recursive \
    || true'

  echo "-- Gateway --"
  echo "TIP: only delete your gateway"
  ibmcloud tg gateways
done
echo "Done Checking"
echo "IBM Cloud PowerVS resources destroyed successfully"