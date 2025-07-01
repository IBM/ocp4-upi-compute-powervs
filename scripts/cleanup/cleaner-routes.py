# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Deletion Criteria : Delete route having route name "powervs-route-1"

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_ROUTE_NAME=
export RESOURCE_POWERVS_VPC_NAME
export RESOURCE_POWERVS_ROUTE_NAME
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
vpc_name = os.getenv("RESOURCE_POWERVS_VPC_NAME")
route_name = os.getenv("RESOURCE_POWERVS_ROUTE_NAME")
# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url('https://us-east.iaas.cloud.ibm.com/v1')
try:    
    vpcs = service.list_vpcs().get_result()['vpcs']
    for vpc in vpcs:
      if(vpc['name'] == vpc_name):
         vpc_id = vpc['id']
         vpc_crn_id = vpc['crn'].split(":")[9]
except ApiException as e:
  print("VPC Operation failed with status code " + str(e.code) + ": " + e.message)

print("[VPC ROUTING TABLES] - [START LISTING] ", vpc_name ," || ", vpc_crn_id)
try: 
    rtables = service.list_vpc_routing_tables(vpc_crn_id).get_result()['routing_tables']
    rtable_id = rtables[0]['id']
    rtable_name = rtables[0]['name']
    print("ROUTING-TABLE-NAME : " , rtable_name )
    rt_routes = service.list_vpc_routing_table_routes(vpc_crn_id, rtable_id).get_result()['routes']
    if(len(rt_routes) == 0):
      print("NO ROUTES FOUND IN ROUTING TABLE : " , rtable_name)
    for route in rt_routes:  
      if(route_name == route['name']):
        print("VPC ROUTE FOUND : ", vpc_name, "||", rtable_name, "||", route['name'], "||", route['id'] )
except ApiException as e:
  print("List Route failed with status code " + str(e.code) + ": " + e.message)


print("[ROUTES] - [START DELETING]")

print("[ROUTES] - [FINISHED CLEANING]")



