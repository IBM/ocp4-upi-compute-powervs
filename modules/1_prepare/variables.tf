################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

variable "cluster_domain" {}
variable "cluster_id" {
  type = string

  validation {
    condition     = length(var.cluster_id) <= 32
    error_message = "Length cannot exceed 32 characters when combined with cluster_id_prefix."
  }
}
variable "bastion" {}

variable "name_prefix" {
  type = string

  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for name_prefix."
  }
}

variable "node_prefix" {
  type = string

  validation {
    condition     = length(var.node_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for node_prefix."
  }
}

variable "service_instance_id" {}
variable "rhel_image_name" {}

variable "private_key" {}
variable "public_key" {}

variable "processor_type" {}
variable "system_type" {}
variable "network_name" {}
variable "network_dns" {}

variable "bastion_health_status" {}
variable "private_network_mtu" {}

variable "rhel_username" {}
variable "ssh_agent" {}
variable "connection_timeout" {}

variable "rhel_subscription_username" {}
variable "rhel_subscription_password" {}
variable "rhel_subscription_org" {}
variable "rhel_subscription_activationkey" {}
variable "ansible_repo_name" {}

variable "rhel_smt" {}