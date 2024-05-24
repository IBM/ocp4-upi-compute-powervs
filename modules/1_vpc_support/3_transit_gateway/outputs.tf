################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "new_tg" {
  value = ibm_tg_gateway.mac_tg_gw.id
}

output "new_tg_name" {
  value = ibm_tg_gateway.mac_tg_gw.name
}

output "new_tg_status" {
  value = ibm_tg_gateway.mac_tg_gw.status
}
