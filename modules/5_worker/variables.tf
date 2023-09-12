################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ignition_mac" {}
variable "key_name" {}
variable "name_prefix" {}
variable "powervs_service_instance_id" {}
variable "powervs_dhcp_network_id" {}
variable "powervs_dhcp_network_name" {}
variable "powervs_dhcp_service" {}
variable "processor_type" {}
variable "rhcos_image_id" {}
variable "system_type" {}

variable "worker" {
  type = object({ count = number, memory = string, processors = string })
  default = {
    count      = 1
    memory     = "16"
    processors = "1"
  }
  validation {
    condition     = lookup(var.worker, "count", 1) >= 1
    error_message = "The worker.count value must be greater than 1."
  }
}