################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

variable "bastion_public_ip" {
  default = "none"
}

variable "ssh_agent" {
  type        = bool
  description = "Enable or disable SSH Agent. Can correct some connectivity issues. Default: false"
  default     = false
}

variable "private_key_file" {
  type        = string
  description = "Path to private key file"
  default     = "${path.cwd}/data/id_rsa"
}

variable "kubeconfig_file" {
  type        = string
  description = "Path to kubeconfig file"
  default     = "../../data/kubeconfig"
}