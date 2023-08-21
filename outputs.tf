################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "cluster_id" {
  value = local.cluster_id
}

output "name_prefix" {
  value = local.name_prefix
}

output "vpc_support_server_ip" {
  description = "The VPC Support Machine's IP - nfs/dns forwarder"
  value       = module.vpc_support.vpc_support_server_ip
}

output "vpc_check_key" {
  description = "The VPC SSH Key that was added/checked against existing keys"
  value       = module.vpc_support.vpc_check_key
}

output "bastion_private_ip" {
  value = module.pvs_prepare.bastion_private_ip
}

output "bastion_public_ip" {
  value = join(", ", module.pvs_prepare.bastion_public_ip)
}