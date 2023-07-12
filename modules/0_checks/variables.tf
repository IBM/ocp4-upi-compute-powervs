################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with user's identity"
  default     = "<key>"
}

variable "vpc_name" {
  type        = string
  description = "The name of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_region" {
  type        = string
  description = "The region of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_zone" {
  type        = string
  description = "The zone of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "powervs_region" {
  type        = string
  description = "The IBM Cloud region where you want to create the workers"
  default     = ""
}

variable "override_region_check" {
  type         = boolean
  desceription = "Set to true if you want to skip region checks."
  default      = false
}