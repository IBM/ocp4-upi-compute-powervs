# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.
#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete security_group associated with the ocp4-upi-compute-ibmcloud-powervs, and remove the security_group with the postfix `*-supp-sg`

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_POWERVS_VPC_NAME=
export RESOURCE_USER_POSTFIX=
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
user_postfix = os.getenv("RESOURCE_USER_POSTFIX")
audit_output = {}
audit_record = {}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url(str(serviceEndpointURL) + "/v1")

print("[SECURITY GROUPS] - [START LISTING]")
print("ASSOCIATED VPC IN POWER CONTROL PLANE: ", vpc_name)
# Listing Security Groups
try:
    sgs = service.list_security_groups(vpc_name=vpc_name).get_result()['security_groups']
    audit_output['security_groups'] = []
    print("SECURITY GROUPS having postfix  as : " , user_postfix )
    for sg in sgs:
      if(sg['name'].endswith(user_postfix)):
        print(sg)
        #print(sg['id'], "\t",  sg['name'], "\t" , sg['crn'], "\t", sg['created_at'])
        sgts = service.list_security_group_targets(security_group_id=sg['id'])
        #print(sgts)
        if(len(sgts.get_result().get("targets")) == 0 ):
          for sgt in sgts.get_result().get("targets"):
            print(sgt['id'] , "\t",  sgt['name'], "\t" , sgt['resource_type'] )
          #sgrs = service.list_security_group_rules(security_group_id=sg['id'])
          #print("SECURITY GROUP RULES FOR : " , sg['name'], " || ", vpc_name) 
          #for sgr in sgrs.get_result().get("rules"):
          #  print(sgr['id'] , "\t", sgr['direction'])
          audit_record = {}
          audit_record['id'] = sg['id']
          audit_record['name'] = sg['name']
          audit_record['crn'] = sg['crn']
          audit_record['created_at'] = sg['created_at']
          audit_output['security_groups'].append(audit_record)
        else:
          print("Aborting cleanup of Security groups as Targets are attached to Security Group :" , sg['name']) 
      
except ApiException as e:
  print("List Security Groups failed with status code " + str(e.code) + ": " + e.message)

try:
  print("[SECURITY GROUPS] - [START DELETING]")
  for resource in audit_output['security_groups']:
      print(resource['id'])
      #response = service.delete_security_group(id=resource['id'])
  print("[SECURITY GROUPS] - [FINISHED CLEANING]")
except ApiException as e:
  print("Delete security groups failed with status code " + str(e.code) + ": " + e.message)