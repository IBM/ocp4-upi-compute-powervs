################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "existing_tg" {
  value = data.ibm_tg_gateway.existing_tg.id
}

output "existing_tg_name" {
  value = data.ibm_tg_gateway.existing_tg.name
}

output "existing_tg_status" {
  value = data.ibm_tg_gateway.existing_tg.status
}
