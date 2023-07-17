################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_tg_gateways" "mac_tg_gws" {
}

locals {
  tg = [for x in data.ibm_tg_gateways.mac_tg_gws.transit_gateways : x if x.name == "${var.vpc_name}-tg"]
}

# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_gateway
resource "ibm_tg_gateway" "mac_tg_gw" {
  count          = local.tg == [] ? 1 : 0
  name           = "${var.vpc_name}-tg"
  location       = var.vpc_region
  global         = true
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection
resource "ibm_tg_connection" "vpc_tg_connection" {
  gateway      = local.tg == [] ? ibm_tg_gateway.mac_tg_gw[0].id : local.tg.id
  network_type = "vpc"
  name         = "${var.vpc_name}-vpc-conn"
  network_id   = data.ibm_is_vpc.vpc.resource_crn
}
