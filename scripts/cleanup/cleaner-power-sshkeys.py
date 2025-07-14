# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.
#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete SSHKeys within the given Power Workspace
Assuming ACCESS_TOKEN will be set from within the bash env.

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export ACCESS_TOKEN=
export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_REGION_CODE=
export P_RESOURCE_CLOUD_INSTANCE=
export P_RESOURCE_CLOUD_CRN=
export P_RESOURCE_SSHKEY_PREFIX=
"""

import ibm_platform_services
import json
import os
import region_endpoint_mapping
import requests
import subprocess
from region_endpoint_mapping import getPowerPublicEndpointURL
from ibm_platform_services.resource_controller_v2 import *
from ibm_platform_services import ResourceControllerV2
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_sdk_core import ApiException


api_key = os.getenv("RESOURCE_MANAGER_APIKEY")
resource_group_name = os.getenv("RESOURCE_GROUP_NAME")
vpc_name = os.getenv("RESOURCE_POWERVS_VPC_NAME")
pcloud_crn = os.getenv("P_RESOURCE_CLOUD_CRN")
pcloud_instance_id = os.getenv("P_RESOURCE_CLOUD_INSTANCE")
sshkey_prefix = os.getenv("P_RESOURCE_SSHKEY_PREFIX")
audit_output = {}
audit_record = {}


print("[POWER SSHKEY] - [START LISTING]")
try:
    ws_target = "ibmcloud pi workspace target " + pcloud_crn
    ssh_output = "ibmcloud pi ssh-key ls --json | jq -r '.name[] | select(.name | startswith(\"" + sshkey_prefix + "\")).name'"
    ws_result = subprocess.run(ws_target, shell=True, capture_output=True, text=True)
    ssh_result = subprocess.run(ssh_output, shell=True, capture_output=True, text=True)
    sshKeys_Output = ssh_result.stdout.splitlines()
    for keyName in sshKeys_Output:
       print("KP :", keyName)
except ApiException as e:
  print("List Instances failed with status code " + str(e.code) + ": " + e.message)

try:
  print("[POWER SSHKEYS] - [START DELETING]")
  '''
  for resource in audit_output['instances']:
    url = serviceEndpointURL + "/pcloud/v1/cloud-instances/" + pcloud_instance_id + "/pvm-instances/" + resource['id']
    headers={"Authorization": os.getenv("ACCESS_TOKEN"), "CRN": os.getenv("P_RESOURCE_CLOUD_CRN"), "Content-Type":"application/json"}
    #pvmInstancesResult = requests.delete(url=url, headers=headers)
  '''
  print("[POWER SSHKEYS] - [FINISHED CLEANING]")
except ApiException as e:
  print("Delete Power instances failed with status code " + str(e.code) + ": " + e.message) 