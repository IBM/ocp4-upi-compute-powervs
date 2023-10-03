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

if [ -z "${WORKSPACE_NAME}" ]
then 
    echo "Failed: no workspace name set"
    return -1
fi

if [ -z "${REGION}" ]
then 
    echo "Failed: no REGION name set"
    return -1
fi

if [ -z "${RESOURCE_GROUP}" ]
then 
    echo "Failed: no RESOURCE_GROUP name set"
    return -1
fi

SERVICE_NAME=power-iaas
SERVICE_PLAN_NAME=power-virtual-server-group

${IBMCLOUD} resource service-instance-create "${WORKSPACE_NAME}" \
    "${SERVICE_NAME}" "${SERVICE_PLAN_NAME}" "${REGION}" -g "${RESOURCE_GROUP}" \
    --allow-cleanup