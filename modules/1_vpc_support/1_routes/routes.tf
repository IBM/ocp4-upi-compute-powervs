################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_is_vpc_routing_table_route" "route_to_powervs" {
  vpc           = var.vpc
  routing_table = var.routing_table
  zone          = var.zone
  name          = "powervs-route-1"
  destination   = var.destination
  action        = "delegate_vpc"
  next_hop      = "0.0.0.0"
}