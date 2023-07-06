################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

variable "bastion_public_ip" {
  type        = list(string)
  description = "List of bastion public IP addresses"
  default     = ["none"]
}
variable "ssh_agent" {}
variable "private_key_file" {}
variable "kubeconfig_file" {}
variable "ibmcloud_region" {}
variable "ibmcloud_zone" {}
variable "system_type" {}
variable "nfs_server" {}
variable "nfs_path" {}
