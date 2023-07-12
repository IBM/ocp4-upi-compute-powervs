################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

### IBM Cloud
ibmcloud_api_key = "<key>"

# VPC
vpc_name   = "<zone>"
vpc_region = "<region>"
vpc_zone   = "<zone>"

# PowerVS
powervs_service_instance_id = "<cloud_instance_ID>"
powervs_region              = "<region>"
powervs_zone                = "<zone>"

# OpenShift Cluster
openshift_api_url = "<openshift_cluster_API_URL>"
openshift_user    = "<openshift_cluster_user>"
openshift_pass    = "<openshift_cluster_pass>"

# Power Instance Configuration
processor_type = "shared"
system_type    = "e980"

# Machine Details
bastion_health_status = "WARNING"
bastion               = { memory = "16", processors = "1", "count" = 1 }
worker                = { memory = "16", processors = "1", "count" = 1 }

# Images for Power Systems
rhel_image_name  = "centos-03112022"
rhcos_image_name = "rhcos-414-92-202306140644-t1"

# Public and Private Key for Bastion Nodes
public_key_file  = "data/compute_id_rsa.pub"
private_key_file = "data/compute_id_rsa"