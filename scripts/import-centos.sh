#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Helper file to import the centos image using the ibmcloud cli

IBMCLOUD=ibmcloud
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ibmcloud plugin install power-iaas -f
fi

POWERVS_CRN=$(${IBMCLOUD} pi sl 2>&1 | grep ${SERVICE_INSTANCE_ID} | awk '{print $1}')
${IBMCLOUD} pi st "${POWERVS_CRN}"

${IBMCLOUD} pi image-create CentOS-Stream-8
echo "Finished importing CentOS-Stream-8"