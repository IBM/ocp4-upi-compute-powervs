#!/bin/bash

# Parse Input values
eval "$(jq -r '@sh "export vpc_region=\(.vpc_region) pvs_region=\(.pvs_region)"')"

# Check if PVS Region is compatible with VPC Region 
if [[ $vpc_region == *"$pvs_region"* ]]
then
# echo "IBM Region $pvs_region is matching with VPC Region $vpc_region". [This needs to be commented to not cause issues for json output]
 status="valid"
else
# echo "IBM Region $pvs_region is not matching with VPC Region $vpc_region". 
 status="invalid"
# exit 1
fi

# Prepare JSON output
#echo -n "{\"status\":\"$status\"}"
jq -n --arg status "$status" '{"status":$status}'

