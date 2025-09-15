# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete Load Balancers within the given VPC.

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_POWERVS_VPC_NAME=
export RESOURCE_REGION_CODE=
"""

import ibm_platform_services
import json
import os
import region_endpoint_mapping
from region_endpoint_mapping import getPublicEndpointURL
from ibm_platform_services.resource_controller_v2 import *
from ibm_platform_services import ResourceControllerV2
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_sdk_core import ApiException

api_key = os.getenv("RESOURCE_MANAGER_APIKEY")
resource_group_name = os.getenv("RESOURCE_GROUP_NAME")
vpc_name = os.getenv("RESOURCE_POWERVS_VPC_NAME")
serviceEndpointURL = getPublicEndpointURL(os.getenv("RESOURCE_REGION_CODE"))
audit_output = {}
audit_record = {}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url(str(serviceEndpointURL) + "/v1")
print("[LOAD BALANCERS] - [START LISTING]")
# Listing Instances
try:
    lbs = service.list_load_balancers(start=None,limit=None ,headers={'vpc_name':vpc_name}).get_result()['load_balancers']
    audit_output['load_balancers'] = []
    for lb in lbs:
        #print(lb)
        #print("#################") 
        print(lb['id'], "\t",  lb['name'], "\t", lb['created_at'])
        audit_record = {}
        audit_record['id'] = lb['id']
        audit_record['name'] = lb['name']
        audit_record['crn'] = lb['crn']
        audit_record['created_at'] = lb['created_at']
        audit_output['load_balancers'].append(audit_record)
except ApiException as e:
  print("List Load Balancers failed with status code " + str(e.code) + ": " + e.message)

try:
  print("[LOAD BALANCERS] - [START DELETING]")
  for resource in audit_output['load_balancers']:
    #response = service.delete_instance(id=resource['id'])
    print(resource['id'])
  print("[LOAD BALANCERS] - [FINISHED CLEANING]")
except ApiException as e:
  print("Delete load-balancers failed with status code " + str(e.code) + ": " + e.message)