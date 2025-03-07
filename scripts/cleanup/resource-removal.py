# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.

#!/usr/bin/env python -W ignore
"""
Removes the resources in a current account/resource group that were deployed by Multi-Arch Compute.

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
vpcs={}

# https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
authenticator = IAMAuthenticator(api_key)
service = VpcV1(authenticator=authenticator)
service.set_service_url('https://us-east.iaas.cloud.ibm.com/v1')
resource_manager_service = ibm_platform_services.ResourceManagerV2(authenticator=authenticator)

resource_controller_url = 'https://resource-controller.cloud.ibm.com'
controller = ResourceControllerV2(authenticator=authenticator)
controller.set_service_url(resource_controller_url)
#resource_controller_service = ResourceControllerV2.new_instance(service_name=service.DEFAULT_SERVICE_NAME)
#resource_controller_service = controller.delete_resource_instance(id='r014-a9e9ae1d-02c2-48c9-a773-4528876ddaf0',recursive=True)
resource_controller_service = controller.delete_resource_instance(id="crn:v1:bluemix:public:is:us-east:a/65b64c1f1c29460e8c2e4bbfbd893c2c::vpc:r014-a9e9ae1d-02c2-48c9-a773-4528876ddaf0",recursive=True)
print ("DELETION DONE")
#resource_controller_service = ResourceControllerV2.new_instance(service_name=service.DEFAULT_SERVICE_NAME)
print("Going for delete_resource_instance")
#resource_controller_service.delete_resource_instance(id="r014-a9e9ae1d-02c2-48c9-a773-4528876ddaf0",recursive=True)