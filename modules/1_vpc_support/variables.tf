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
  description = "The VPC Name"
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

variable "supp_vm_image_name" {
  type        = string
  description = "The image name for the support VM."
  default     = "ibm-centos-stream-9-amd64-5"
}

variable "public_key_file" {
  type        = string
  description = "Path to public key file"
  default     = "data/id_rsa.pub"
  # if empty, will default to ${path.cwd}/data/id_rsa.pub
}

variable "public_key" {
  type        = string
  description = "Public key"
  default     = ""
  # if empty, will read contents of file at var.public_key_file
}

variable "openshift_api_url" {
  type        = string
  description = "The API URL of the OpenShift Cluster"
  default     = "https://api.example.ocp-multiarch.xyz:6443"
}

variable "vpc_supp_public_ip" {
  type        = bool
  description = "Set to true if you want to skip region checks."
  default     = false
}

variable "powervs_machine_cidr" {}
variable "override_transit_gateway_name" {}
variable "mac_tags" {}