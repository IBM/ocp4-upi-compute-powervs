#!/usr/bin/env bash

################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# runs an audit and cleanup across the CIS instance for a given set of variables
# More than 2 day old, it'll be cleaned up.
# Pre-Req: must already be logged into ibmcloud

# Command:
# scripts/cleanup/cis.sh multi-arch-cicd-resource-group ex.ex.ex.net

# Variables:
# Setup the Instances Array which is used subsequently to find the domains.
if [[ "${SHELL}" == */bin/zsh* ]]
then
    typeset -a INSTANCES
else
    declare -a INSTANCES
fi

# The target instance
TARGET_INSTANCE=""

# Functions:
# Runs before the execution of audit
pre() {
    echo "[Configuring the CIS Plugin]"
    # Setup
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
    ${IBMCLOUD} plugin update cloud-internet-services -q
}

# Finds the CIS instance
find_cis_instance() {
    RESOURCE_GROUP_NAME="${1}"
    DOMAIN_NAME="${2}"
    echo "[Finding the CIS Instance]"
    RESOURCE_GROUP_ID="$(${IBMCLOUD} resource groups --output json | jq -r --arg rgn "${RESOURCE_GROUP_NAME}" '.[] | select(.name == $rgn).id')"
    export CIS_INSTANCES="$(${IBMCLOUD} cis instances --output json | jq -r --arg rgi "${RESOURCE_GROUP_ID}" '.[] | select(.resource_group_id == $rgi).crn')"
    I=0
    for INSTANCE in $(echo ${CIS_INSTANCES})
    do
        echo "INSTANCE: ${INSTANCE}"
        INSTANCES[I]="${INSTANCE}"
        I=$(expr $I + 1)
    done
}

# Find the given domain and returns the id
find_the_domain() { 
    DOMAIN_NAME="${1}"
    echo "[Find the domain id for the CIS instances - ${DOMAIN_NAME}]"
    for INSTANCE in $(echo ${INSTANCES})
    do
        echo "INSTANCE: ${INSTANCE}"
        ${IBMCLOUD} cis instance-set "${INSTANCE}"
        DOMAIN_ID="$(${IBMCLOUD} cis domains --output json | jq -r --arg domain "${DOMAIN_NAME}" '.[] | select(.name == $domain).id')"
        if [ ! -z "${DOMAIN_ID}" ]
        then
            echo "${DOMAIN_ID} is found"
            TARGET_INSTANCE="${DOMAIN_ID}"
            break
        fi
    done
}

# prints out the current records
audit() {
    echo "[Auditing the CIS DNS Records]"
    JSON_BODY="$(mktemp)"
    PAGE=1
    ERRORS=0
    while true
    do
        ${IBMCLOUD} cis instance-set "${TARGET_INSTANCE}"
        ${IBMCLOUD} cis dns-records "${TARGET_INSTANCE}" --output json --per-page 1000 --page ${PAGE} > "${JSON_BODY}"

        if [[ $? != 0 ]]
        then
            ERRORS=$(expr $ERRORS + 1)
            if [[ $ERRORS = 5 ]]
            then
                echo "Encountered 5 errors"
                break
            else
                echo "backing off due to an error: 15 seconds"
                sleep 15
                continue
            fi
        fi

        RECORD_LENGTH="$(cat ${JSON_BODY} | jq -r '. | length')"
        if [ "${RECORD_LENGTH}" = "0" ]
        then
            echo "DONE processing"
            break
        else
            echo "- [Retrieving the target records - Page 1 ${PAGE}]"
            for RECORD in $(cat ${JSON_BODY} | jq -r --arg after_date "${AFTER_DATE}" '.[]? | select(.created_on > $after_date) | [.id,.content,.created_on] | @csv')
            do
                echo $RECORD
            done
        fi
        PAGE=$(expr $PAGE + 1)
    done
}

# cleans up any record older than the current day
cleanup() {
    echo "[Cleaning the CIS DNS Records]"
    JSON_BODY="$(mktemp)"
    PAGE=1
    ERRORS=0
    while true
    do
        ${IBMCLOUD} cis dns-records "${TARGET_INSTANCE}" --output json --per-page 1000 --page ${PAGE} > "${JSON_BODY}"

        if [[ $? != 0 ]]
        then
            ERRORS=$(expr $ERRORS + 1)
            if [[ $ERRORS = 5 ]]
            then
                echo "Encountered 5 errors"
                break
            else
                echo "backing off due to an error: 15 seconds"
                sleep 15
                continue
            fi
        fi

        RECORD_LENGTH="$(cat ${JSON_BODY} | jq -r '. | length')"
        if [ "${RECORD_LENGTH}" = "0" ]
        then
            echo "DONE processing"
            break
        else
            echo "- [Retrieving the target records - Page 1 ${PAGE}]"
            for DETAIL in $(cat ${JSON_BODY} | jq -r --arg after_date "${AFTER_DATE}" '.[]? | [.id,.created_on] | @csv')
            do
                ID=$(echo $DETAIL | awk -F ',' '{print $1}')
                CREATED_ON=$(echo $DETAIL | awk -F ',' '{print $2}')
                if [[ "${CREATED_ON}" != *${PROTECTED_DATE_1}* && "${CREATED_ON}" != *${PROTECTED_DATE_2}* ]]
                then
                    ${IBMCLOUD} cis dns-record-delete $(echo ${TARGET_INSTANCE} | tr -d '"') ${ID}
                fi
            done
        fi
        PAGE=$(expr $PAGE + 1)
    done
}

pre
find_cis_instance $1
find_the_domain $2
audit
cleanup