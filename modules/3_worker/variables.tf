################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "name_prefix" {}
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

variable "rhcos_image_name" {}

variable "powervs_network_name" {}


variable "system_type" {}
variable "public_key_name" {}
variable "processor_type" {}

variable "service_instance_id" {
  type        = string
  description = "The cloud instance ID of your account"
  default     = ""
}

variable "bastion_ip" {}


variable "powervs_dns_forwarders" {}
variable "ignition_url" {}