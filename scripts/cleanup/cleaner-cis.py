# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2024.

"""
Cleans up CIS records older than 2 days old

python3 -m venv .
source bin/activate
python3 -m pip install --upgrade ibm-cloud-sdk-core
python3 -m pip install --upgrade ibm-cloud-networking-services
python3 -m pip install --upgrade ibm-platform-services

❯ IBMCLOUD_CIS_CRN=<CRN> \
    IBMCLOUD_IAM_KEY=<API_KEY> \
    IBMCLOUD_CIS_DOMAIN_NAME=<DOMAIN_NAME> \
    python3 cleaner-cis.py
"""

from ibm_cloud_sdk_core.authenticators import IAMAuthenticator
from ibm_cloud_networking_services import DnsSvcsV1
from ibm_cloud_networking_services import ZonesV1
from ibm_cloud_sdk_core.api_exception import ApiException
from ibm_cloud_networking_services.dns_records_v1 import DnsRecordsV1
import os
from ibm_platform_services import ResourceControllerV2, ResourceManagerV2
from datetime import datetime, timedelta
import datetime

from ibm_cloud_sdk_core.utils import datetime_to_string, string_to_datetime

# Variables
service_url = "https://api.cis.cloud.ibm.com"

print("[CIS] - [STARTED CLEANING]")
# Authenticate
authenticator = IAMAuthenticator(os.getenv("IBMCLOUD_IAM_KEY"))
controller = ResourceControllerV2(authenticator=authenticator)

crn = os.getenv("IBMCLOUD_CIS_CRN")
domain_name = os.getenv("IBMCLOUD_CIS_DOMAIN_NAME")

zone = ZonesV1(authenticator=authenticator, crn=crn)
zone.set_service_url(service_url)

response = zone.list_zones()
assert response is not None
assert response.status_code == 200
zones = response.get_result()['result']

print("Zones:")
zone_id=""
for zone in zones:
    #print(zone)
    if zone["name"] == domain_name:
        zone_id = zone["id"]
print("")

print("Zone ID for '" + domain_name + "' is '" + zone_id + "'")
dnszone = DnsRecordsV1(authenticator=authenticator, crn=crn, zone_identifier=zone_id)
dnszone.set_service_url(service_url)

response = dnszone.list_all_dns_records()
assert response is not None
assert response.status_code == 200

records = response.get_result()['result']

# Prune time is 2 day
delta = timedelta(hours=48)
prune_time = datetime.datetime.now(datetime.timezone.utc) - timedelta(seconds=172800)

print("")

print("Pruning records older than 2 days:")
for record in records:
    if "sergio-ocp" in record['name']:
        print("auto skipping")

    if string_to_datetime(record['created_on']) < prune_time:
        print(record['created_on'] + " = " + record['name'])
        print(record)
        d_record = dnszone.delete_dns_record(dnsrecord_identifier=record["id"])
        print(d_record)

print("[CIS] - [FINISHED CLEANING]")