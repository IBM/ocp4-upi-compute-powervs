################################################################
# Copyright 2026 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "worker_objects" {
  description = "All provisioned ibm_pi_instance worker objects"
  value       = module.worker.worker_objects
}
