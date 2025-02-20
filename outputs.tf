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

output "transit_gateway_name" {
  description = "The name of the Transit Gateway"
  value       = module.vpc_support.transit_gateway_name
}

output "transit_gateway_status" {
  description = "The staus for the Transit Gateway"
  value       = module.vpc_support.transit_gateway_status
}

output "bastion_private_ip" {
  value       = module.worker.bastion_private_ip
  description = "The private ip of the bastion"
}

output "bastion_public_ip" {
  value       = join(", ", module.pvs_prepare.bastion_public_ip)
  description = "The public ip of the bastion"
}
