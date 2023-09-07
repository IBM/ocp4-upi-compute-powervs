################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_public_network_id" {
  value = ibm_pi_network.bastion_public_network.network_id
}

output "bastion_public_network_name" {
  value = ibm_pi_network.bastion_public_network.pi_network_name
}

output "bastion_public_network_cidr" {
  value = ibm_pi_network.bastion_public_network.pi_cidr
}

output "powervs_dhcp_network_id" {
  value = local.server[0].network_id
}

output "powervs_dhcp_network_name" {
  value = local.server[0].network_name
}

output "powervs_dhcp_service" {
  value = local.server[0]
}
