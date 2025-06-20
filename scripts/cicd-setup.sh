#!/usr/bin/env bash

################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

ibmcloud plugin install -f cloud-internet-services vpc-infrastructure cloud-object-storage power-iaas is

REGION=au-syd
WORKSPACE_NAME=rdr-mac-${REGION}-n1
SERVICE_NAME=power-iaas
SERVICE_PLAN_NAME=power-virtual-server-group

# create workspace for powervs from cli
echo "Display all the variable values:"
POWERVS_REGION=$(bash scripts/region.sh "${REGION}")
echo "VPC Region is ${REGION}"
echo "PowerVS region is ${POWERVS_REGION}"
echo ""

echo "Resource Group is [${RESOURCE_GROUP}]"

# 1. Create the service instance
ibmcloud pi workspace create "${WORKSPACE_NAME}" \
    --plan public \
    --datacenter "${POWERVS_REGION}" \
    --json \
    --group "${RESOURCE_GROUP}" 2>&1

# 2. Store the CRN
CRN=$(ibmcloud pi workspace ls --json | jq -r '.Payload.workspaces[] | select(.Name == "'"${WORKSPACE_NAME}"'").CRN')

# 3. Tag the resource for easier MAC management
ibmcloud resource tag-attach --tag-names "mac-power-worker" \
    --resource-id "${CRN}" --tag-type user

# 4. Wait for active 

# Waits for the created instance to become active... after 10 minutes it fails and exists
# Example content for TEMP_STATE
# active
# crn:v1:bluemix:public:power-iaas:osa21:a/3c24cb272ca44aa1ac9f6e9490ac5ecd:6632ebfa-ae9e-4b6c-97cd-c4b28e981c46::
COUNTER=0
SERVICE_STATE=""
while [ -z "${SERVICE_STATE}" ]
do
  COUNTER=$((COUNTER+1)) 
  TEMP_STATE="$(ibmcloud resource service-instances -g "${RESOURCE_GROUP}" --output json --type service_instance \
    | jq -r '.[] | select(.crn == "'"${CRN}"'") | .state')"
  echo "Current State is: ${TEMP_STATE}"
  echo ""
  if [ "${TEMP_STATE}" == "active" ]
  then
    SERVICE_STATE="FOUND"
  elif [[ $COUNTER -ge 20 ]]
  then
    SERVICE_STATE="ERROR"
    echo "Service has not come up... login and verify"
    exit 2
  else
    echo "Waiting for service to become active... [30 seconds]"
    sleep 30
  fi
done

echo "SERVICE_STATE: ${SERVICE_STATE}"

# 5. CREATE CENTOS IMAGE
# The Centos-Stream-9 image is stock-image on PowerVS.
# This image is available across all PowerVS workspaces.
# The VMs created using this image are used in support of ignition on PowerVS.
echo "Creating the Centos Stream Image"
echo "PowerVS Target CRN is: ${CRN}"
ibmcloud pi workspace target "${CRN}"
ibmcloud pi image list
ibmcloud pi image create Centos-Stream-9 --json
echo "Import image status is: $?"

# This CRN is useful when manually destroying.
echo "PowerVS Service CRN: ${CRN}"

# 6/7 Setup Transit Gateway and Transit Gateway Connections

# 8. Create Network `ocp-net`

# 9. Create Transit Gateway
ibmcloud tg gateway-create \
    --name ${WORKSPACE_NAME}-tg \
    --location ${REGION} \
    --routing global \
    --resource-group-id $(ibmcloud resource groups 2>&1 | grep ${RESOURCE_GROUP} | awk '{print $2}')

# 10. Attach Transit Gateway
DL_ID=$(ibmcloud dl gateways | grep ${WORKSPACE_NAME} | awk '{print $1}')
DL_CRN=$(ibmcloud dl gateway ${DL_ID} --output json | jq -r .crn)
ibmcloud tg connection-create \
    --name ${WORKSPACE_NAME}-conn \
    --network-id ${DL_CRN} \
    --network-type directlink

echo "done cicd setup"