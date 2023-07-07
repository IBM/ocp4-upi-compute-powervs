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
  value = module.prepare.bastion_vip == "" ? null : module.prepare.bastion_vip
}

output "bastion_private_ip" {
  value = join(", ", module.prepare.bastion_ip)
}

output "bastion_public_ip" {
  value = join(", ", module.prepare.bastion_public_ip)
}

output "bastion_ssh_command" {
  value = "ssh -i ${var.private_key_file} ${var.rhel_username}@${module.prepare.bastion_public_ip[0]}"
}