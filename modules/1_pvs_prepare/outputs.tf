################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_ip" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_ip
}

output "bastion_public_ip" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_public_ip
}