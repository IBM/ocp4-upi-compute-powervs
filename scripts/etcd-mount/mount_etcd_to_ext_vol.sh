#!/bin/bash
################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################
set -o errexit
set -uo pipefail

IBMCLOUD=ibmcloud
IBMCLOUD_HOME_FOLDER=""
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ${IBMCLOUD} plugin install power-iaas -f
fi

if [ ! -z "${IBMCLOUD_HOME_FOLDER}" ]
then
    IBMCLOUD_HOME_FOLDER="${1}"
    function ic() {
    HOME=${IBMCLOUD_HOME_FOLDER} ibmcloud "$@"
    }
    IBMCLOUD=ic
fi

var_tier="10iops-tier"
var_rg="${ENV_RESOURCE_GROUP:-ocp-dev-resource-group}"
var_tag="rdr-multi-arch-etcd"
var_vpc_prefix=rdr-ca
var_rand_id=$(echo "$(openssl rand -hex 4)")
vsi_out=$(${IBMCLOUD} is instances | grep ${var_filter} | grep master | awk -vOFS=":" '{print $1,$2,$9}');
arr=( $(sed 's/:/ /g' <<<"$vsi_out") );
i=0;
for count in 0 1 2; do
  id=${arr[i]};
  name=${arr[i+1]};
  region=${arr[i+2]};
  vol_create_command="${IBMCLOUD} is volume-create auto-etcd-vol-${var_rand_id}-${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag}";
  VOLUME_ID=$(${IBMCLOUD} is volume-create auto-etcd-vol-${var_rand_id}-${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag} | jq .id | tr -d "'\"");
  VOL_STATUS=$( ${IBMCLOUD} is volumes | grep ${VOLUME_ID} | awk '{print $3}' );
  while [ "$VOL_STATUS" != "available" ]
  do
       VOL_STATUS=$( ${IBMCLOUD} is volumes | grep ${VOLUME_ID} | awk '{print $3}' );
  done
  echo "Block Volume created successfully with Volume ID : ${VOLUME_ID}";	
  vol_attach_command="${IBMCLOUD} is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag}"
  ATTACH_COMMAND=$(${IBMCLOUD} is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag});
  echo "Volume Attached Successfully to the Master Node : ${id}"
  i=$((i+3));
done

#Volume Attachment done. Going for etcd migration.
if [ -z "${CICD}" ]
then
echo "We do not backup etcd"
exit 0
fi


