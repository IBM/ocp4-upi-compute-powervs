#!/usr/bin/env bash

################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This script cleans up the security group changes made when adding PowerVS Compute to an IPI Intel Cluster.

# Variables are required
API_KEY="${1}"
REGION="${2}"
RESOURCE_GROUP="${3}"
VPC="${4}"
POWERVS_MACHINE_CIDR="${5}"

# Get sg_prefix to be used for OCP created Security Groups
sg_prefix=$(echo "$VPC" | rev | cut -c5- | rev)
if [ -z "$sg_prefix" ]
then
  echo "Security Groups name can not be constructed hence exiting"
  exit -1
else
  echo "SG Prefix is - '$sg_prefix'"
fi

# Checks to see if the ibmcloud exists, if not, installs
# Also takes care of the plugin installs
if [ -z "$(command -v ibmcloud)" ]
then
  echo "ibmcloud CLI doesn't exist, installing"
  curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
  ibmcloud plugin install -f vpc-infrastructure is
fi

# Login to ibmcloud
ibmcloud login --apikey "${API_KEY}" -r "${REGION}" -g "${RESOURCE_GROUP}"

##########################################################################################
# Deletes provided Security Group
##########################################################################################
delete_security_group() {

# Input Parameters
INPUT_SG_NAME="${1}"
INPUT_VPC="${2}"
sg_name_found=$(ibmcloud is security-groups --vpc "$INPUT_VPC" | grep "$INPUT_SG_NAME" | awk '{print $1}')

if [ ! -z "${sg_name_found}" ]
then
  echo "Deleting Security Group with Name '$INPUT_SG_NAME' having Id '$sg_name_found'"
  # Delete Security Group
  ibmcloud is security-group-delete "$INPUT_SG_NAME" --vpc "$INPUT_VPC" -f
  
  # Confirm Security Group is deleted
  deleted="false"
  for n in {1..5};
  do
    sg_name_check=$(ibmcloud is security-groups --vpc "$INPUT_VPC" | grep "$INPUT_SG_NAME" | awk '{print $1}')

    if [ -z "${sg_name_check}" ]
    then
      deleted="true"
      break
    else 
      sleep 2
    fi

  done

  if [ "$deleted" != "true" ]
  then
    echo "Security Group '$INPUT_SG_NAME' is not deleted"
  fi

else
  echo "Security Group '$INPUT_SG_NAME' is not found"
fi

}

##########################################################################################
# Function to delete specific Security Group Rule from given Security Group
##########################################################################################
delete_security_group_rule() {

# Input Parameters
INPUT_SG_NAME="${1}"
INPUT_VPC="${2}"
INPUT_DIRECTION="${3}"
INPUT_REMOTE="${4}"
INPUT_PORT_PROTOCOL="${5}"

# Get Security Group Rule for supplied Security Group
sg_rule_found=$(ibmcloud is security-group-rules "$INPUT_SG_NAME" --vpc "$INPUT_VPC"| grep "$INPUT_DIRECTION" | grep "$INPUT_REMOTE" | grep "$INPUT_PORT_PROTOCOL" | awk '{print $1}')

# Delete Security Group Rule
if [ ! -z "${sg_rule_found}" ]
then
  echo "Deleting Security Group Rule with ID '$sg_rule_found'"
  ibmcloud is security-group-rule-delete "$INPUT_SG_NAME" $sg_rule_found --vpc "$INPUT_VPC" -f

  # Confirm Security Group Rule is deleted
  deleted="false"
  for n in {1..5};
  do
    sg_rule_check=$(ibmcloud is security-group-rules "$INPUT_SG_NAME" --vpc "$INPUT_VPC"| grep "$INPUT_DIRECTION" | grep "$INPUT_REMOTE" | grep "$INPUT_PORT_PROTOCOL" | awk '{print $1}')

    if [ -z "${sg_rule_check}" ]
    then
      deleted="true"
      break
    else 
      sleep 2
    fi

  done

  if [ "$deleted" != "true" ]
  then
    echo "Security Group Rule with ID '$sg_rule_found' is still not deleted"
  fi

else
  echo "Security Group Rule with Direction '$INPUT_DIRECTION', is not found for Security Group '$INPUT_SG_NAME' with Remote '$INPUT_REMOTE' for Port/Protocol '$INPUT_PORT_PROTOCOL'"
fi

}

##############################
# Main Logic

# Delete Security Group
delete_security_group "$VPC-supp-sg" "$VPC"

# Delete SG Rule for control-plane
delete_security_group_rule "$sg_prefix-sg-control-plane" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "22623"
delete_security_group_rule "$sg_prefix-sg-control-plane" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "6443"

# Delete SG Rule for cp-internal
delete_security_group_rule "$sg_prefix-sg-cp-internal" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "2379"
delete_security_group_rule "$sg_prefix-sg-cp-internal" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "10257"

# Delete SG Rule for kube-api-lb
delete_security_group_rule "$sg_prefix-sg-kube-api-lb" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "22623"

delete_security_group_rule "$sg_prefix-sg-kube-api-lb" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "22623"
delete_security_group_rule "$sg_prefix-sg-kube-api-lb" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "6443"
delete_security_group_rule "$sg_prefix-sg-kube-api-lb" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "80"
delete_security_group_rule "$sg_prefix-sg-kube-api-lb" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "443"

# Delete SG Rule for cluster-wide
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "6081"	
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "4789"
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "9100"
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "9537"
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "22"
delete_security_group_rule "$sg_prefix-sg-cluster-wide" "$VPC" "inbound" "0.0.0.0/0" "icmp"

# Delete SG Rule for openshift-net
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "tcp Ports:Min=30000"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "udp Ports:Min=30000"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "udp Ports:Min=500"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "tcp Ports:Min=9000"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "udp Ports:Min=9000"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "10250"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "inbound" "$POWERVS_MACHINE_CIDR" "udp Ports:Min=4500"

delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "tcp Ports:Min=30000"
delete_security_group_rule "$sg_prefix-sg-openshift-net" "$VPC" "outbound" "$POWERVS_MACHINE_CIDR" "udp Ports:Min=30000"

echo "Completed deleting the security groups rules and support security group"

