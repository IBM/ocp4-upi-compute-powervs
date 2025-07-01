# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete SSH Keys with prefix `p-px` and postfix `-keypair`

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_USER_PREFIX=
export RESOURCE_USER_POSTFIX=
"""

import ibm_platform_services
import json
import os
from ibm_platform_services.resource_controller_v2 import *
from ibm_platform_services import ResourceControllerV2
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_sdk_core import ApiException

api_key = os.getenv("RESOURCE_MANAGER_APIKEY")
resource_group_name = os.getenv("RESOURCE_GROUP_NAME")
user_prefix = os.getenv("RESOURCE_USER_PREFIX")
user_postfix = os.getenv("RESOURCE_USER_POSTFIX")
audit_output = {}
audit_record = {}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url('https://us-east.iaas.cloud.ibm.com/v1')

print("[SSH KEYS] - [START LISTING]")
# Listing keys
try:
    keys = service.list_keys().get_result()['keys']
    audit_output['security_keys'] = []
    for key in keys:
      if(key['name'].startswith(user_prefix) and key['name'].endswith(user_postfix)):
        print(key['id'], "\t",  key['name'], "\t", key['created_at'])
        audit_record = {}
        audit_record['id'] = key['id']
        audit_record['name'] = key['name']
        audit_record['crn'] = key['crn']
        audit_record['created_at'] = key['created_at']
        audit_output['security_keys'].append(audit_record)
except ApiException as e:
  print("List Keys failed with status code " + str(e.code) + ": " + e.message)

print("[SSH KEYS] - [START DELETING]")
for resource in audit_output['security_keys']:
   if ":key:" in resource["crn"]:
      response = service.delete_key(id=resource["id"])

print("[SSH KEYS] - [FINISHED CLEANING]")



