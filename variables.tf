################################################################
# Copyright 2026 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with user's identity"
  sensitive   = true
}

################################################################
# Configure the IBM PowerVS provider
################################################################

variable "powervs_service_instance_id" {
  type        = string
  description = "The PowerVS service instance ID (workspace GUID)"
  default     = ""
}

variable "powervs_region" {
  type        = string
  description = "The IBM Cloud region of the PowerVS workspace (e.g. us-south)"
  default     = ""
}

variable "powervs_zone" {
  type        = string
  description = "The zone of the IBM Cloud region for the PowerVS workspace (e.g. us-south)"
  default     = ""
}

################################################################
# SSH key and naming
################################################################

variable "key_name" {
  type        = string
  description = "Name of the SSH key already registered in the PowerVS workspace"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for all provisioned resource names (max 32 chars)"
  default     = ""
  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for name_prefix."
  }
}

################################################################
# PowerVS network (pre-existing resources)
################################################################

variable "powervs_network_id" {
  type        = string
  description = "ID of the existing PowerVS network to attach workers to"
}

variable "powervs_bastion_name" {
  type        = string
  description = "Name of the existing PowerVS bastion instance"
}

variable "powervs_machine_cidr" {
  type        = string
  description = "CIDR of the PowerVS network (e.g. 192.168.200.0/24). Used to derive the ignition server IP."
  default     = "192.168.200.0/24"
}

################################################################
# Instance configuration
################################################################

variable "processor_type" {
  type        = string
  description = "Processor mode for worker instances (shared/dedicated)"
  default     = "shared"
}

variable "system_type" {
  type        = string
  description = "PowerVS machine type for worker instances (s922/e980/s1022/s1080)"
  default     = "s1022"
}

variable "rhcos_image_id" {
  type        = string
  description = "ID of the RHCOS image already imported into the PowerVS workspace"
}

variable "worker" {
  type        = object({ count = number, memory = string, processors = string })
  description = "Worker instance configuration: count, memory (GiB), and processors"
  default = {
    count      = 1
    memory     = "16"
    processors = "1"
  }
  validation {
    condition     = lookup(var.worker, "count", 1) >= 0
    error_message = "The worker.count value must be greater than or equal to 0."
  }
  nullable = false
}

################################################################
# Ignition / bastion details
################################################################

variable "ignition_mac" {
  type        = string
  description = "MAC address of the bastion's private network interface"
}

variable "ignition_ip" {
  type        = string
  description = "IP of the ignition server (bastion private IP). Leave empty to derive from powervs_machine_cidr host 3."
  default     = ""
}

variable "bastion_public_ip" {
  type        = string
  description = "Public IP address of the bastion instance"
}

################################################################
# SSH connectivity
################################################################

variable "private_key_file" {
  type        = string
  description = "Path to the private SSH key file"
  default     = "data/id_rsa"
}

variable "ssh_agent" {
  type        = bool
  description = "Enable SSH agent forwarding. Can correct some connectivity issues."
  default     = false
}

################################################################
# CI/CD
################################################################

variable "cicd" {
  type        = bool
  description = "Enables additional checks used by CI/CD pipelines"
  default     = false
}
