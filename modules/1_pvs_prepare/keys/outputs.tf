################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "pvs_pubkey_name" {
  value = ibm_pi_key.key.name
}