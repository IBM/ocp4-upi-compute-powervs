################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "mac_vpc_subnets" {
  value = module.subnets.mac_vpc_subnets
}