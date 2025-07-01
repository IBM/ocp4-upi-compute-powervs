# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete images with prefix `p-px` and postfix `-rhcos-img`

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

print("[VPC IMAGES] - [START LISTING]")
# Listing Images
try:
    images = service.list_images().get_result()['images']
    audit_output['images'] = [] 
    for image in images:
        if(image['owner_type'] == 'user' and image['name'].startswith(user_prefix) and image['name'].endswith(user_postfix) ):
            print(image['id'], "\t",  image['name'] , "\t", image['created_at'])
            audit_record = {}
            audit_record['id'] = image['id']
            audit_record['name'] = image['name']
            audit_record['crn'] = image['crn']
            audit_record['created_at'] = image['created_at']
            audit_output['images'].append(audit_record)
except ApiException as e:
  print("List VPC images failed with status code " + str(e.code) + ": " + e.message)

print("[VPC IMAGES] - [START DELETING]")
try:
  for resource in audit_output['images']:
    print(resource['id'])
    #response = service.delete_image(id=resource['id'])
  print("[VPC IMAGES] - [FINISHED CLEANING]")
except ApiException as e:
  print("Delete VPC images failed with status code " + str(e.code) + ": " + e.message)



