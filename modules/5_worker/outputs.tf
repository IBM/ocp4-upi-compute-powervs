################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "worker_ip" {
  value = data.ibm_pi_instance_ip.worker[*].ip
}