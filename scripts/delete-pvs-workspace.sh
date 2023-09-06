#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

IBMCLOUD=ibmcloud
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ibmcloud plugin install power-iaas -f
fi

echo "cleaning up workspace"
${IBMCLOUD} resource service-instance-delete "${POWERVS_SERVICE_INSTANCE_ID}" -g "${RESOURCE_GROUP}" --force --recursive \

# # Delete the workspace created
# if [ -f "${SHARED_DIR}/POWERVS_SERVICE_CRN" ]
# then
#   echo "Starting the delete on the PowerVS resource"
#   POWERVS_CRN=$(< "${SHARED_DIR}/POWERVS_SERVICE_CRN")
#   POWERVS_SERVICE_INSTANCE_ID=$(echo "${POWERVS_CRN}" | sed 's|:| |g' | awk '{print $NF}')
#   if [ -f "${SHARED_DIR}/RESOURCE_GROUP" ]
#   then
#     # service-instance-delete uses a CRN
#     RESOURCE_GROUP=$(cat "${SHARED_DIR}/RESOURCE_GROUP")
#     ic resource service-instance-delete "${POWERVS_SERVICE_INSTANCE_ID}" -g "${RESOURCE_GROUP}" --force --recursive \
#       || true
#   else
#     echo "WARNING: No RESOURCE_GROUP or POWERVS_SERVICE_INSTANCE_ID found, not deleting the workspace"
#   fi
# fi