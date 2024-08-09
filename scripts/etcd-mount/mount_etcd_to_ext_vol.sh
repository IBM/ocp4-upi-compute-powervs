#!/bin/bash
################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################
set -o errexit
set -uo pipefail

var_tier="10iops-tier"
var_rg="ocp-dev-resource-group"
var_tag="rdr-multi-arch-etcd"
vsi_out=$(ibmcloud is instances | grep rdr-ca | grep master | awk -vOFS=":" '{print $1,$2,$9}');
echo $vsi_out;
arr=( $(sed 's/:/ /g' <<<"$vsi_out") )
i=0;
for count in 0 1 2; do
  id=${arr[i]};
  name=${arr[i+1]};
  region=${arr[i+2]};
  VOL_CREATE_COMMAND="ibmcloud is volume-create auto-etcd-vol${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag}"
  echo ${VOL_CREATE_COMMAND};
  VOLUME_ID=$(ibmcloud is volume-create auto-etcd-vol${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag} | jq .id | tr -d "'\"")
  echo "VOLUME ID IS : ${VOLUME_ID}"
  vol_attach_command="ibmcloud is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag}"
  echo ${vol_attach_command};
  ATTACH_COMMAND=$(ibmcloud is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag});
  i=$((i+3));
done