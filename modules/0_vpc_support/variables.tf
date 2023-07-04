################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "vpc_name" {
  type        = string
  description = "The VPC Name"
  default     = ""
}

variable "dns_vm_image_name" {
  type        = string
  description = "The image name for the DNS VM."
  default     = "ibm-centos-stream-9-amd64-3"
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
