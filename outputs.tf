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

output "bastion_private_vip" {
  value = module.pvs_prepare.bastion_ip
}

output "bastion_public_ip" {
  value = join(", ", module.pvs_prepare.bastion_public_ip)
}

output "worker_ip" {
  value = module.worker.worker_ip
}