# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2024.

"""
Cleans up COS records older than 2 days old

python3 -m venv .
source bin/activate 
python3 -m pip install --upgrade ibm-cloud-sdk-core
python3 -m pip install --upgrade ibm-cloud-networking-services
python3 -m pip install --upgrade ibm-platform-services

export RESOURCE_MANAGER_URL=https://resource-controller.cloud.ibm.com
export RESOURCE_MANAGER_AUTHTYPE=iam
export RESOURCE_MANAGER_APIKEY=
export RESOURCE_GROUP_NAME=
export RESOURCE_CONTROLLER_APIKEY=
"""

from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_platform_services import ResourceControllerV2

import json
import os
import ibm_platform_services
from ibm_platform_services.resource_controller_v2 import *
from ibm_platform_services import ResourceControllerV2
from ibm_cloud_sdk_core.utils import datetime_to_string, string_to_datetime
from datetime import datetime, timedelta
import datetime

api_key = os.getenv("RESOURCE_MANAGER_APIKEY")
resource_group_name = os.getenv("RESOURCE_GROUP_NAME")

# create the authenticator
authenticator = IAMAuthenticator(api_key)

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

print("[COS] - [STARTED CLEANING]")

all_results = []
pager = ResourceInstancesPager(
   client=controller,

 )
while pager.has_next():
  next_page = pager.get_next()
  assert next_page is not None
  all_results.extend(next_page)

print("Found the following cos instances in the resource group:")
for resource in all_results:
   if ":cloud-object-storage:" in resource["crn"]:
    #print(resource)
    if resource["resource_group_id"] == resource_group_id:
        print(resource["created_at"] + " " + resource["name"] + " " + resource["crn"])
print("")

# Prune time is 2 day
delta = timedelta(hours=48)
prune_time = datetime.datetime.now(datetime.timezone.utc) - timedelta(seconds=172800)

# Filter through the COS buckets to find the multi-arch-compute ones
resource_controller_service = ResourceControllerV2.new_instance()

print("Deleting COS Buckets older than 2 days old: ")
idx = 0
cos_results = []
for resource in all_results:
   if ":cloud-object-storage:" in resource["crn"]:
        if resource["resource_group_id"] == resource_group_id:
            if string_to_datetime(resource['created_at']) < prune_time:
                print(resource["created_at"] + " " + resource["name"] + " " + resource["crn"])
                idx = idx + 1
                cos_results.extend(resource)
                #print(resource)
                response = resource_controller_service.delete_resource_instance(
                    id=resource["guid"],
                    recursive=True
                )
print("There were => " + str(idx))

print("[COS] - [FINISHED CLEANING]")
