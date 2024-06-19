#!/usr/bin/env bash

################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# runs an audit across the COS instance for a given set of variables
# More than 2 day old, it'll be cleaned up.
# Pre-Req: must already be logged into ibmcloud

# Command:
# scripts/cleanup/cos.sh multi-arch-cicd-resource-group

RESOURCES="$(mktemp)"

# Functions:

# Runs before the execution of audit
pre() {
    echo "[Configuring the COS Plugin]"
    IBMCLOUD=ibmcloud
    if [[ "${OSTYPE}" == *darwin* ]]
    then
        echo "OSTYPE: darwin"
        AFTER_DATE=$(date -j -v-1d +"%Y-%m-%d")
        PROTECTED_DATE_1=$(date -j +"%Y-%m-%d")
        PROTECTED_DATE_2=$(date -j -v-1d +"%Y-%m-%d")
    elif [[ $(type -t ic) == function ]]
    then
        IBMCLOUD=ic
        AFTER_DATE=$(date --date="now -1 day" +%Y-%m-%d)
        PROTECTED_DATE_1=$(date --date="now" +%Y-%m-%d)
        PROTECTED_DATE_2=$(date --date="now -1 day" +%Y-%m-%d)
    fi
    ${IBMCLOUD} plugin update cloud-object-storage -q
}

# Download the resources
# Assumption: if we have over 10K instances, we have big problems.
download_resource_details() {
    RESOURCE_GROUP_NAME="${1}"
    echo "[Finding the CIS Instance]"
    RESOURCE_GROUP_ID="$(${IBMCLOUD} resource groups --output json | jq -r --arg rgn "${RESOURCE_GROUP_NAME}" '.[] | select(.name == $rgn).id')"

    ${IBMCLOUD} resource search "(service_name:cloud-object-storage AND type:resource-instance) AND (doc.resource_group_id:${RESOURCE_GROUP_ID})" \
    --output json --limit 10000 --is-reclaimed false > ${RESOURCES}
    echo "FILE: ${RESOURCES} is populated..."
    echo "Size of file is: $(cat ${RESOURCES} | jq -r '.items | length')"
}

# audit
audit () {
    for COS_DETAILS in $(cat ${RESOURCES} | jq -rc '.items[]  | select(.crn | contains (":cloud-object-storage:"))')
    do
        NAME=$(echo "${COS_DETAILS}" | jq -r .name)
        CRN=$(echo "${COS_DETAILS}" | jq -r .crn)
        CREATED_DATE=$(${IBMCLOUD} resource service-instance ${CRN} --output json | jq -rc '.[] | .created_at')
        echo "${NAME},${CREATED_DATE},${CRN}"
    done
}

# Cleanup Instances
cleanup_instances () {
    for COS_DETAILS in $(cat ${RESOURCES} | jq -rc '.items[]  | select(.crn | contains (":cloud-object-storage:"))')
    do
        NAME=$(echo "${COS_DETAILS}" | jq -r .name)
        CRN=$(echo "${COS_DETAILS}" | jq -r .crn)
        CREATED_DATE=$(${IBMCLOUD} resource service-instance ${CRN} --output json | jq -rc '.[] | .created_at')
        if [[ "${CREATED_DATE}" != *${PROTECTED_DATE_1}* && "${CREATED_DATE}" != *${PROTECTED_DATE_2}* ]]
        then
            echo "CREATED ON IS TOO NEW ${CREATED_DATE}"
            break
        fi
        if [[ $(echo "${NAME},${CRN}" | grep -c "crn:") == 1 ]]
        then
            echo "Processing: ${NAME},${CRN}"
            ${IBMCLOUD} resource service-instance-delete ${CRN} --f --recursive || true
            sleep 10
        fi
    done
}

# Hard Cleanup Cleans up any additional resources
hard_cleanup_instances () {
    for COS_DETAILS in $(cat ${RESOURCES} | jq -rc '.items[]  | select(.crn | contains (":cloud-object-storage:"))')
    do
        NAME=$(echo "${COS_DETAILS}" | jq -r .name)
        CRN=$(echo "${COS_DETAILS}" | jq -r .crn)
        CREATED_DATE=$(${IBMCLOUD} resource service-instance ${CRN} --output json | jq -rc '.[] | .created_at')
        if [[ "${CREATED_DATE}" != *${PROTECTED_DATE_1}* && "${CREATED_DATE}" != *${PROTECTED_DATE_2}* ]]
        then
            echo "CREATED ON IS TOO NEW ${CREATED_DATE}"
            break
        fi

        if [[ $(echo "${NAME},${CRN}" | grep -c "crn:" ) == 1 ]]
        then
            echo "Processing: ${NAME},${CRN}"
            ${IBMCLOUD} cos config crn --crn ${CRN} --force
            if [ "$(${IBMCLOUD} cos buckets --output json | jq -r '.Buckets | length')" != "0" ]
            then
                for BUCKET in $(${IBMCLOUD} cos buckets --output json | jq -r '.Buckets | .[].Name')
                do
                    TARGET_REGION=$(${IBMCLOUD} cos bucket-location-get --bucket "${BUCKET}" | grep 'Region:' | awk '{print $2}')
                    ${IBMCLOUD} target -r "${TARGET_REGION}"
                    echo "BUCKET: ${BUCKET}"
                    KEY_COUNT=$(${IBMCLOUD} cos list-objects-v2 --bucket ${BUCKET} --output json | jq -r '.KeyCount')
                    while [[ "${KEY_COUNT}" != "0" ]]
                    do
                        for KEY in $(${IBMCLOUD} cos list-objects-v2 --bucket ${BUCKET} --output json | jq -r '.Contents[].Key')
                        do
                            echo "KEYS: ${KEY}"
                            ${IBMCLOUD} cos object-delete --bucket ${BUCKET} --key ${KEY} --force
                        done
                        KEY_COUNT=$(${IBMCLOUD} cos list-objects-v2 --bucket ${BUCKET} --output json | jq -r '.KeyCount')
                    done
                    break
                done

                ${IBMCLOUD} resource service-instance-delete "${CRN}" --f --recursive || true
            fi
            sleep 10
        fi
    done
}

# Main
if [ -z "${1}" ]
then
    echo "Failed to pass resource group"
    exit 1
fi

pre
download_resource_details ${1}

if [ ! -z "${2}" ]
then
    # Exit early with only audit
    audit
    exit 0
fi

cleanup_instances

sleep 30

echo "redownloading the resources"
download_resource_details ${1}
hard_cleanup_instances

echo "Done COS Cleanup"