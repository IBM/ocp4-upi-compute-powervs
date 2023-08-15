################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_is_vpc_routing_table_route" "route_to_powervs" {
  vpc           = data.ibm_is_vpc.vpc.id
  routing_table = data.ibm_is_vpc.vpc.default_routing_table
  zone          = data.ibm_is_vpc.vpc.subnets[0].zone
  name          = "powervs-route-1"
  destination   = var.powervs_machine_cidr
  action        = "delegate_vpc"
  next_hop      = "0.0.0.0"
}