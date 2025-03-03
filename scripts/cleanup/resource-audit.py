# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Audits the resources in a current account/resource group that were deployed by Multi-Arch Compute.

python3 -m venv .
source bin/activate
python3 -m pip install -r requirements.txt 

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_USER_PREFIX=
"""

from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_platform_services import ResourceControllerV2

import json
import os
from ibm_cloud_sdk_core.utils import datetime_to_string, string_to_datetime

import ibm_platform_services
from ibm_platform_services.resource_controller_v2 import *
from ibm_platform_services import ResourceControllerV2
from ibm_vpc import VpcV1
from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_sdk_core import ApiException

from datetime import datetime, timedelta
import datetime

api_key = os.getenv("RESOURCE_MANAGER_APIKEY")
resource_group_name = os.getenv("RESOURCE_GROUP_NAME")
user_prefix = os.getenv("RESOURCE_USER_PREFIX")
audit_output = {}
audit_record = {}
vpc_routes = []
vpc_route = {}
vpcs={}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url('https://us-east.iaas.cloud.ibm.com/v1')

#  Listing VPCs and routes
print("List VPCs")
try:
    vpcs = service.list_vpcs().get_result()['vpcs']
    if vpcs is not None: 
      audit_output['vpcs'] = []
      for vpc in vpcs:    
        print(vpc['resource_group']['id'], "\t",  vpc['name'], "\t" , vpc['default_security_group']['name'], "\t" ,vpc['crn'], "\t" , vpc['created_at'])
        vpc_crn_id = vpc['crn'].split(":")[9]
        audit_record = {}
        audit_record['id'] = vpc['resource_group']['id']
        audit_record['name'] = vpc['name']
        audit_record['crn'] = vpc['crn']
        audit_record['created_at'] = vpc['created_at']
        audit_output['vpcs'].append(audit_record)
except ApiException as e:
  print("List VPC failed with status code " + str(e.code) + ": " + e.message)

try:
    rtables = service.list_vpc_routing_tables(vpc_crn_id).get_result()['routing_tables']
    rtable_id = rtables[0]['id']
    rt_routes = service.list_vpc_routing_table_routes(vpc_crn_id, rtable_id).get_result()['routes']
    if rt_routes is not None:
      audit_output['routes'] = []
      for route in rt_routes:
        vpc_route['id'] = route['id']
        vpc_route['name'] = route['name']
        vpc_route['crn'] = vpc_crn_id
        vpc_route['created_at'] = route['created_at'] 
        vpc_routes.append(vpc_route)  
      print("\nList VPC Routes")
      for route in vpc_routes:
        print(route['id'], "\t", route['name'], "\t" , route['created_at'])
        audit_record = {}
        audit_record['id'] = route['id']
        audit_record['name'] = route['name']
        audit_record['crn'] = route['crn']
        audit_record['created_at'] = route['created_at']
        audit_output['routes'].append(audit_record)
except ApiException as e:
  print("List Route failed with status code " + str(e.code) + ": " + e.message)

#  Listing Subnets
print("\nList Subnets")
try:
    subnets = service.list_subnets().get_result()['subnets']
    if subnets is not None:
      audit_output['subnets'] = []
      for subnet in subnets:
  #    print(subnet['id'], "\t",  subnet['name'], "\t" , subnet['created_at'] )
        audit_record = {}
        audit_record['id'] = subnet['id']
        audit_record['name'] = subnet['name']
        audit_record['crn'] = subnet['crn']
        audit_record['created_at'] = subnet['created_at']
        audit_output['subnets'].append(audit_record)
except ApiException as e:
  print("List subnets failed with status code " + str(e.code) + ": " + e.message)

# Listing Security Groups
print("\nList Security Groups")
try:
    sgs = service.list_security_groups().get_result()['security_groups']
    if sgs is not None:
      audit_output['security_groups'] = []    
      for sg in sgs:
  #     print(sg['id'], "\t",  sg['name'], "\t", sg['created_at'])
        audit_record = {}
        audit_record['id'] = sg['id']
        audit_record['name'] = sg['name']
        audit_record['crn'] = sg['crn']
        audit_record['created_at'] = sg['created_at']
        audit_output['security_groups'].append(audit_record)
except ApiException as e:
  print("List Security Groups failed with status code " + str(e.code) + ": " + e.message)

# Listing keys
print("\nList Keys")
try:
    keys = service.list_keys().get_result()['keys']
    if keys is not None:
      audit_output['security_keys'] = []
      for key in keys:
          if(key['name'].startswith(user_prefix)):
              print(key['id'], "\t",  key['name'], "\t", key['created_at'])
              audit_record = {}
              audit_record['id'] = key['id']
              audit_record['name'] = key['name']
              audit_record['crn'] = key['crn']
              audit_record['created_at'] = key['created_at']
              audit_output['security_keys'].append(audit_record)
except ApiException as e:
  print("List Keys failed with status code " + str(e.code) + ": " + e.message)

# Listing Images
print("\nList Images")
try:
    images = service.list_images().get_result()['images']
    if images is not None:
      audit_output['images'] = [] 
      for image in images:
          if(image['owner_type'] == 'user'):
              print(image['id'], "\t",  image['name'] , "\t", image['created_at'])
              audit_record = {}
              audit_record['id'] = image['id']
              audit_record['name'] = image['name']
              audit_record['crn'] = image['crn']
              audit_record['created_at'] = image['created_at']
              audit_output['images'].append(audit_record)
except ApiException as e:
  print("List images failed with status code " + str(e.code) + ": " + e.message)

# Listing Load Balancers
print("\nList Load Balancers")
try:
    lbs = service.list_load_balancers().get_result()['load_balancers']
    if lbs is not None:
      audit_output['load_balancers'] = []
      for lb in lbs:
          print(lb['id'], "\t",  lb['name'], "\t", lb['created_at'])
          audit_record = {}
          audit_record['id'] = lb['id']
          audit_record['name'] = lb['name']
          audit_record['crn'] = lb['crn']
          audit_record['created_at'] = lb['created_at']
          audit_output['load_balancers'].append(audit_record)
except ApiException as e:
  print("List Load Balancers failed with status code " + str(e.code) + ": " + e.message)

# Listing Instances
print("\nList Instances")
try:
    instances = service.list_instances().get_result()['instances']
    if instances is not None:
      audit_output['instances'] = [] 
      for instance in instances:
          print(instance['id'], "\t",  instance['name'], "\t", instance['created_at'])
          audit_record = {}
          audit_record['id'] = instance['id']
          audit_record['name'] = instance['name']
          audit_record['crn'] = instance['crn']
          audit_record['created_at'] = instance['created_at']
          audit_output['instances'].append(audit_record)
    print(json.dumps(audit_output))
except ApiException as e:
  print("List Instances failed with status code " + str(e.code) + ": " + e.message)

resource_manager_service = ibm_platform_services.ResourceManagerV2(authenticator=authenticator)
response = resource_manager_service.list_resource_groups(
  include_deleted=True,
)
print( response )
assert response is not None
assert response.status_code == 200

# Pick off the resource group id so we can use it in the ResourceController to filter on resources
print("\nList Resource Groups")
try:
  resource_group_list = response.get_result()["resources"]
  resource_group_id=""
  for resource_group in resource_group_list:
    if resource_group["name"] == resource_group_name:
        resource_group_id = resource_group["id"]
        print("resource_group_id is: " + resource_group_id)
except ApiException as e:
  print("List Resource Groups failed with status code " + str(e.code) + ": " + e.message)
