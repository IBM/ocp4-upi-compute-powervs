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
