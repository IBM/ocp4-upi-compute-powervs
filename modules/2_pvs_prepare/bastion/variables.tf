################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "powervs_service_instance_id" {}
variable "name_prefix" {}
variable "bastion" {}
variable "system_type" {}
variable "processor_type" {}
variable "bastion_health_status" {}
variable "key_name" {}
variable "private_key_file" {}
variable "public_key" {}
variable "ssh_agent" {}
variable "connection_timeout" {}
variable "cluster_domain" {}
variable "private_network_mtu" {}
variable "rhel_username" {}
variable "rhel_smt" {}
variable "rhel_subscription_org" {}
variable "rhel_subscription_username" {}
variable "rhel_subscription_password" {}
variable "rhel_subscription_activationkey" {}
variable "bastion_image_id" {}
variable "bastion_storage_pool" {}
variable "bastion_public_network_id" {}
variable "bastion_public_network_name" {}
variable "bastion_public_network_cidr" {}
variable "powervs_network_id" {}
variable "powervs_network_name" {}
variable "powervs_network_cidr" {}
variable "vpc_support_server_ip" {}