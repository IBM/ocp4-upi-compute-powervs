################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "bastion_public_ip" {
  type        = list(string)
  description = "List of bastion public IP addresses"
  default     = ["none"]
}
variable "ssh_agent" {}
variable "private_key_file" {}
variable "powervs_region" {}
variable "powervs_zone" {}
variable "system_type" {}
variable "nfs_server" {}
variable "nfs_path" {}
variable "remove_nfs_deployment" {}
variable "name_prefix" {}
variable "worker" {}
variable "cicd" {}

variable "openshift_api_url" {}
variable "openshift_user" {}
variable "openshift_pass" {}

variable "vpc_name" {}
variable "vpc_resource_group" {}