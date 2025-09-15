################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_ip" {
  value = local.ignition_ip
}

output "worker_objects" {
  value = ibm_pi_instance.worker
}