################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "new_tg" {
  value = ibm_tg_connection.vpc_tg_connection.id
}