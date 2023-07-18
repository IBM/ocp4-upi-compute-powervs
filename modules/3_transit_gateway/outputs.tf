################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "mac_tg_gateway" {
  value = data.ibm_tg_gateway.mac_tg_gw.connections
}

output "mac_vpc_subnets" {
  value = data.ibm_is_subnets.vpc_subnets.subnets[*].ipv4_cidr_block
}