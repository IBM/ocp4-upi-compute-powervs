################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_ip" {
  depends_on = [null_resource.bastion_init]
  value      = data.ibm_pi_instance_ip.bastion_ip.*.ip
}

output "bastion_public_ip" {
  depends_on = [null_resource.bastion_packages]
  value      = data.ibm_pi_instance_ip.bastion_public_ip.*.external_ip
}

output "gateway_ip" {
  value = data.ibm_pi_network.network.gateway
}

output "cidr" {
  value = data.ibm_pi_network.network.cidr
}

output "public_cidr" {
  value = ibm_pi_network.public_network.pi_cidr
}

output "bastion_vip" {
  depends_on = [null_resource.bastion_init]
  value      = local.bastion_count > 1 ? ibm_pi_network_port_attach.bastion_external_vip[0].pi_network_port_ipaddress : ""
}

output "bastion_internal_vip" {
  depends_on = [null_resource.bastion_init]
  value      = local.bastion_count > 1 ? ibm_pi_network_port_attach.bastion_internal_vip[0].pi_network_port_ipaddress : ""
}

output "bastion_external_vip" {
  depends_on = [null_resource.bastion_init]
  value      = local.bastion_count > 1 ? ibm_pi_network_port_attach.bastion_internal_vip[0].public_ip : ""
}
