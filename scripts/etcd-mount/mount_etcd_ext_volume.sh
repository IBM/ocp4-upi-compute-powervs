################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
#################################################################


#!/bin/bash
set -o errexit
set -uo pipefail


IBMCLOUD=ibmcloud
IBMCLOUD_HOME_FOLDER=""
CICD=""

if [ -z "${CICD}" ]
then
   echo "We do not backup etcd"
   #exit 0
fi

sh ocp_login.sh

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


#var_tier="10iops-tier"
#var_rg="ocp-dev-resource-group"
#var_rg="${ENV_RESOURCE_GROUP:-ocp-dev-resource-group}"
#var_tag="rdr-multi-arch-etcd"
var_rand_id=$(echo "$(openssl rand -hex 4)");
#var_vpc_prefix=rdr-mac-mkul18
vsi_out=$(${IBMCLOUD} is instances | grep ${var_vpc_prefix} | grep master | awk -vOFS=":" '{print $1,$2,$9}');
#echo $vsi_out;
arr=( $(sed 's/:/ /g' <<<"$vsi_out") )
i=0;
for count in 0 1 2; do
  id=${arr[i]};
  name=${arr[i+1]};
  region=${arr[i+2]};
  vol_create_command="${IBMCLOUD} is volume-create auto-etcd-vol-${var_rand_id}-${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag}"
#  echo ${vol_create_command};
  VOLUME_ID=$(${IBMCLOUD} is volume-create auto-etcd-vol-${var_rand_id}-${count} ${var_tier} ${region} --capacity 20 --resource-group-name ${var_rg} --output JSON --tags ${var_tag} | jq .id | tr -d "'\"")
  VOL_STATUS=$( ${IBMCLOUD} is volumes | grep ${VOLUME_ID} | awk '{print $3}' );
  while [ "$VOL_STATUS" != "available" ]
  do
        VOL_STATUS=$( ${IBMCLOUD} is volumes | grep ${VOLUME_ID} | awk '{print $3}' );
  done

  vol_attach_command="${IBMCLOUD} is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag}"
  echo ${vol_attach_command};
  ATTACH_COMMAND=$(${IBMCLOUD} is instance-volume-attachment-add auto-attach-vol${count} ${id} ${VOLUME_ID} --auto-delete true --output JSON --tags ${var_tag});
  echo "Volume Attached Successfully to the Master Node : ${name}"
  echo "Waiting while the attachment is activated"
  sleep 10
  chk_query="${IBMCLOUD} is instance-volume-attachments ${name}"
  echo ${chk_query}
  if [ -z "$(ibmcloud is instance-volume-attachments ${name} --output json | jq -r '.[] | select(.status != "attached")')" ]
     then
         echo "Delaying as not all volumes are finished attaching to instance"
         sleep 60
  fi
  i=$((i+3));
done

#Volume Attachment done. Time for etcd migration
sleep 30s
echo "Going for mc-update-file"
oc apply -f 98-master-lib-etcd-mc.yaml --kubeconfig=auth/kubeconfig
# adding a sleep 30 here is not harmful or causing unnecessary delays.
sleep 30
echo "Waiting on the mcp/master to update"
oc wait --for=condition=updated mcp/master --timeout=50m --kubeconfig=auth/kubeconfig

echo "etcd migration done successfully."
#etcd migration done Verification start
i=0;
for count in 0 1 2; do
   name=${arr[i+1]}
   echo "Logging inside Node : ${name}"
   mount_out=$(oc debug --as-root=true node/$name -- chroot /host grep -w  "/var/lib/etcd" /proc/mounts)
   echo "Mountpoint : ${mount_out} "
   if [[ ${mount_out} = "" ]]; then
     echo "etcd mount fail for : ${name}"
     exit 0
   fi
   i=$((i+3))
done
