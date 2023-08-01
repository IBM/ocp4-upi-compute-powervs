################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_ip" {
  depends_on = [null_resource.bastion_init]
  value      = local.bastion_private_ip
}

output "bastion_public_ip" {
  depends_on = [null_resource.manage_packages]
  value      = data.ibm_pi_instance_ip.bastion_public_ip.*.external_ip
}