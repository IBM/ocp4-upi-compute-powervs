################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "pvs_pubkey_name" {
  value = "${var.name_prefix}-keypair"
}