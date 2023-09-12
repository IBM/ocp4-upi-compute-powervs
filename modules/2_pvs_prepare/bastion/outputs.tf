################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_mac" {
  value = ibm_pi_instance.bastion[0].pi_network[0].mac_address
}

output "bastion_public_ip" {
  depends_on = [null_resource.manage_packages]
  value      = data.ibm_pi_instance_ip.bastion_public_ip.*.external_ip
}