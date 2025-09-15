# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.
#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete instances within the given Power Workspace
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
"""

import ibm_platform_services
import json
import os
import region_endpoint_mapping
import requests
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
audit_output = {}
audit_record = {}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
serviceEndpointURL = getPowerPublicEndpointURL(os.getenv("RESOURCE_REGION_CODE"))

print("[POWER NETWORKS] - [START LISTING]")
try:
    url = serviceEndpointURL + "/pcloud/v1/cloud-instances/" + pcloud_instance_id + "/networks"
    headers={"Authorization": os.getenv("ACCESS_TOKEN"), "CRN": os.getenv("P_RESOURCE_CLOUD_CRN"), "Content-Type":"application/json"}
    networksResult = requests.get(url=url, headers=headers)
    networks = networksResult.json()
    audit_output['networks'] = []
    for network in networks['networks']:
      print(network['networkID'], "\t",  network['name'], "\t", network['crn'], "\t" , network['type'])
      audit_record = {}
      audit_record['id'] = network['networkID']
      audit_record['name'] = network['name']
      audit_record['crn'] = network['crn']
      audit_record['type'] = network['type']
      audit_output['networks'].append(audit_record)
except ApiException as e:
  print("List Power Networks failed with status code " + str(e.code) + ": " + e.message)

try:
  print("[POWER NETWORKS] - [START DELETING]")
  for resource in audit_output['networks']:
    if(resource['type'] == "pub-vlan"):
      url = serviceEndpointURL + "/pcloud/v1/cloud-instances/" + pcloud_instance_id + "/networks/" + resource['id']
      headers={"Authorization": os.getenv("ACCESS_TOKEN"), "CRN": os.getenv("P_RESOURCE_CLOUD_CRN"), "Content-Type":"application/json"}
      #pvmInstancesResult = requests.delete(url=url, headers=headers)
  print("[POWER NETWORK] - [FINISHED CLEANING]")
except ApiException as e:
  print("Delete Power instances failed with status code " + str(e.code) + ": " + e.message) 