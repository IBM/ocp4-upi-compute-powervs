# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2024.

"""
Cleans up VPC records older than 2 days old

python3 -m venv .
source bin/activate
python3 -m pip install --upgrade ibm-cloud-sdk-core
python3 -m pip install --upgrade ibm-cloud-networking-services
python3 -m pip install --upgrade ibm-platform-services
python3 -m pip install --upgrade ibm-cos-sdkpip install --upgrade "ibm-vpc>=0.23.0"

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
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

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url('https://us-east.iaas.cloud.ibm.com/v1')

#  Listing VPCs
print("List VPCs")
try:
    vpcs = service.list_vpcs().get_result()['vpcs']
except ApiException as e:
  print("List VPC failed with status code " + str(e.code) + ": " + e.message)

for vpc in vpcs:
    print(vpc['resource_group']['id'], "\t",  vpc['name'])

resource_manager_service = ibm_platform_services.ResourceManagerV2(authenticator=authenticator)
response = resource_manager_service.list_resource_groups(
  include_deleted=True,
)
assert response is not None
assert response.status_code == 200

# Pick off the resource group id so we can use it in the ResourceController to filter on resources
resource_group_list = response.get_result()["resources"]
resource_group_id=""
for resource_group in resource_group_list:
    if resource_group["name"] == resource_group_name:
        resource_group_id = resource_group["id"]
        print("resource_group_id is: " + resource_group_id)
print("")

resource_controller_url = 'https://resource-controller.cloud.ibm.com'
controller = ResourceControllerV2(authenticator=authenticator)
controller.set_service_url(resource_controller_url)

print("[VPCs] - [STARTED CLEANING]")

print("Found the following cos instances in the resource group:")
for resource in vpcs:
    if vpc['resource_group']['id'] == resource_group_id:
        print(resource["created_at"] + " " + resource["name"] + " " + resource["crn"])
print("")

# Prune time is 2 day
delta = timedelta(hours=48)
prune_time = datetime.datetime.now(datetime.timezone.utc) - timedelta(seconds=172800)

# Filter through the COS buckets to find the multi-arch-compute ones
for resource in vpcs:
    if vpc['resource_group']['id'] == resource_group_id:
        print(resource["created_at"] + " " + resource["name"] + " " + resource["crn"])


print("[VPCs] - [FINISHED CLEANING]")