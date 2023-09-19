################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_mac" {
  value = ibm_pi_network_port_attach.bastion_priv_net.macaddress
}

output "bastion_public_ip" {
  depends_on = [null_resource.manage_packages]
  value      = [local.ext_ip]
}

output "powervs_bastion_name" {
  value = ibm_pi_instance.bastion[0].pi_instance_name
}