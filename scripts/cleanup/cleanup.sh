#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Facilitates the cleanup
# usage: vpc_name service_instance_id api_key region
# it does not delete the VPC or PowerVS workspace

# Cleans up the failed prior jobs
function cleanup_multi_arch_compute() {
  local vpc_name="${1}"
  local service_instance_id="${2}"
  local api_key="${3}"
  local region="${4}"

  echo "Cleaning up the Transit Gateways"
  for GW in $(ibmcloud tg gateways --output json | jq -r '.[].id')
  do
    echo "Checking the resource_group and location for the transit gateways ${GW}"
    VALID_GW=$(ibmcloud tg gw "${GW}" --output json | jq -r '. | select(.name | contains("'${vpc_name}'"))')
    if [ -n "${VALID_GW}" ]
    then
      TG_CRN=$(echo "${VALID_GW}" | jq -r '.crn')
      TAGS=$(ibmcloud resource search "crn:\"${TG_CRN}\"" --output json | jq -r '.items[].tags[]' | grep "mac-cicd-${version}")
      if [ -n "${TAGS}" ]
      then
        for CS in $(ibmcloud tg connections "${GW}" --output json | jq -r '.[].id')
        do 
          ibmcloud tg connection-delete "${GW}" "${CS}" --force
          sleep 30
        done
        ibmcloud tg gwd "${GW}" --force
        echo "waiting up a minute while the Transit Gateways are removed"
        sleep 60
      fi
    fi
  done

  echo "Cleaning up workspaces for ${service_instance_id}"
  for CRN in $(ibmcloud pi workspace ls 2> /dev/null | grep "${service_instance_id}" | awk '{print $1}')
  do
    echo "Targetting power cloud instance"
    ibmcloud pi workspace target "${CRN}"

    echo "Deleting the PVM Instances"
    for INSTANCE_ID in $(ibmcloud pi instance ls --json | jq -r '.pvmInstances[] | .id')
    do
      echo "Deleting PVM Instance ${INSTANCE_ID}"
      ibmcloud pi instance delete "${INSTANCE_ID}" --delete-data-volumes
    done
    sleep 60

    echo "Deleting the Images"
    for IMAGE_ID in $(ibmcloud pi images ls --json | jq -r '.images[].imageID')
    do
      echo "Deleting Images ${IMAGE_ID}"
      ibmcloud pi image delete "${IMAGE_ID}"
      sleep 60
    done

    echo "Deleting the Network"
    for NETWORK_ID in $(ibmcloud pi network ls 2>&1 | grep -v ocp-net | awk '{print $1}')
    do
      echo "Deleting network ${NETWORK_ID}"
      ibmcloud pi network delete "${NETWORK_ID}"
      sleep 60
    done

    # ibmcloud resource service-instance-update "${CRN}" --allow-cleanup true
    # sleep 30
    # ibmcloud resource service-instance-delete "${CRN}" --force --recursive
    echo "Done Deleting the ${CRN}"
  done

  echo "Deleting the default route"
  ibmcloud target -r "${region}"
  VPC_ID=$(ibmcloud is vpcs | grep "${vpc_name}" | awk '{print $1}')
  for RT in $(ibmcloud is vpc-routing-tables ${VPC_ID} --output json 2> /dev/null | jq -r '.[].id')
  do
    ibmcloud is vpc-routing-table-route-delete ${VPC_ID} ${RT} powervs-route-1 --force
  done

  VSI_ID=$(ibmcloud is ins ${vpc_name} 2> /dev/null | grep supp-vsi | awk '{print $1}')
  if [ -n "${VSI_ID}" ]
  then
    ibmcloud is ind ${vpc_name} ${VSI_ID} --force 
  fi

  echo "Done cleaning up"
}

echo "usage: vpc_name service_instance_id api_key region"
cleanup_multi_arch_compute "${1}" "${2}" "${3}" "${4}"