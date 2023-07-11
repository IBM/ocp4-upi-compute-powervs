################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

variable "cluster_domain" {
  default = "example.com"
}
variable "cluster_id" {
  default = "test-ocp"
}

variable "vpc_dns_forwarders" {
  default = "161.26.0.7; 161.26.0.8"
}

variable "name_prefix" {}
variable "node_prefix" {}

variable "bastion_ip" {}
variable "bastion_public_ip" {}
variable "gateway_ip" {}

variable "cidr" {}
variable "rhel_username" {}
variable "private_key" {}
variable "ssh_agent" {}
variable "connection_timeout" {}

variable "openshift_client_tarball" {}
variable "openshift_install_tarball" {}

variable "helpernode_repo" { default = "https://github.com/redhat-cop/ocp4-helpernode" }
variable "helpernode_tag" { default = "main" }
variable "install_playbook_repo" { default = "https://github.com/ocp-power-automation/ocp4-playbooks" }
variable "install_playbook_tag" { default = "main" }

variable "ansible_support_version" {}