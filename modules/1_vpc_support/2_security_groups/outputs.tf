################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "sg_id" {
  value = local.sg_id
}

output "cp_internal_sg_id" {
  value = local.cp_internal_sg[0].id
}