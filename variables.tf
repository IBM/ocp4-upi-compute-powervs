################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

################################################################
# Configure the IBM Cloud provider
################################################################
variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with user's identity"
  default     = "<key>"
}

variable "service_instance_id" {
  type        = string
  description = "The cloud instance ID of your account"
  default     = ""
}

variable "ibmcloud_region" {
  type        = string
  description = "The IBM Cloud region where you want to create the resources"
  default     = ""
}

variable "ibmcloud_zone" {
  type        = string
  description = "The zone of an IBM Cloud region where you want to create Power System resources"
  default     = ""
}

################################################################
# Configure the workers to be added to the compute plane
################################################################
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

variable "public_key_name" {
  type    = string
  default = "<none>"
}

variable "ignition_hostname" {
  type    = string
  default = "<none>"
}

variable "rhcos_image_name" {
  type        = string
  description = "Name of the rhcos image that you want to use for the workers"
  default     = "rhcos-4.13"
}

variable "processor_type" {
  type        = string
  description = "The type of processor mode (shared/dedicated)"
  default     = "shared"
}

variable "system_type" {
  type        = string
  description = "The type of system (s922/e980)"
  default     = "s922"
}

variable "network_name" {
  type        = string
  description = "The name of the network to be used for deploy operations"
  default     = "ocp-net"

  validation {
    condition     = var.network_name != ""
    error_message = "The network_name is required and cannot be empty."
  }
}

variable "dns_forwarders" {
  type    = string
  default = "8.8.8.8;8.8.4.4"
}

# The Ignition File 
variable "ignition_file" {
  type    = string
  default = "data/worker.ign"

  validation {
    condition     = var.ignition_file != ""
    error_message = "The ignition_file is required and cannot be empty."
  }

  validation {
    condition     = fileexists(var.ignition_file)
    error_message = "The ignition file doesn't exist."
  }

  validation {
    condition     = file(var.ignition_file) != ""
    error_message = "The ignition secret file shouldn't be empty."
  }
}