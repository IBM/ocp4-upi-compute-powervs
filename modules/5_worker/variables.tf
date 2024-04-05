################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ignition_mac" {}
variable "ignition_ip" {}
variable "key_name" {}
variable "name_prefix" {}
variable "powervs_service_instance_id" {}
variable "powervs_dhcp_network_id" {}
variable "powervs_dhcp_network_name" {}
variable "powervs_dhcp_service" {}
variable "powervs_bastion_name" {}
variable "processor_type" {}
variable "rhcos_image_id" {}
variable "system_type" {}
variable "use_fixed_network" {}
variable "private_key_file" {}
variable "ssh_agent" {}
variable "bastion_public_ip" {}
variable "cicd" {}
variable "worker" {
  default = {
    count      = 1
    memory     = "16"
    processors = "1"
  }
  type        = object({ count = number, memory = string, processors = string })
  description = "The worker configuration details. You may have 0 or more workers"
  validation {
    condition     = lookup(var.worker, "count", 1) >= 0
    error_message = "The worker.count value must be greater than 0."
  }
  nullable = false
}
