################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "cluster_id" {}
variable "ansible_repo_name" {}
variable "bastion" {}
variable "bastion_health_status" {}
variable "cloud_conn_name" {}
variable "cluster_domain" {}
variable "connection_timeout" {}
variable "enable_snat" {}
variable "powervs_machine_cidr" {}
variable "name_prefix" {}
variable "powervs_region" {}
variable "powervs_service_instance_id" {}
variable "private_key" {}
variable "private_network_mtu" {}
variable "processor_type" {}
variable "powervs_dns_forwarders" {}
variable "public_key" {}
variable "powervs_network_name" {}
variable "rhcos_image_name" {}
variable "rhcos_import_image" {}
variable "rhcos_import_image_filename" {}
variable "rhcos_import_image_region_override" {}
variable "rhcos_import_image_storage_type" {}
variable "rhel_image_name" {}
variable "rhel_subscription_org" {}
variable "rhel_subscription_password" {}
variable "rhel_subscription_username" {}
variable "rhel_username" {}
variable "ssh_agent" {}
variable "system_type" {}
variable "vpc_crn" {}
variable "vpc_support_server_ip" {}