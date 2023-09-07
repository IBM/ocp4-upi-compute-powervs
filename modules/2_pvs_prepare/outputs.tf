################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_ip" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_private_ip
}

output "bastion_public_ip" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_public_ip
}

output "pvs_pubkey_name" {
  depends_on = [module.keys]
  value      = module.keys.pvs_pubkey_name
}

output "powervs_dhcp_network_id" {
  depends_on = [module.network]
  value      = var.override_network_name != null ? module.existing_network[0].powervs_dhcp_network_id : module.network[0].powervs_dhcp_network_id
}

output "powervs_dhcp_network_name" {
  depends_on = [module.network]
  value      = var.override_network_name != null ? var.override_network_name : module.network[0].powervs_dhcp_network_name
}

output "rhcos_image_id" {
  depends_on = [module.images]
  value      = module.images.rhcos_image_id
}