################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_tg_gateways" "mac_tg_gws" {
}

locals {
  tg = [for x in data.ibm_tg_gateways.mac_tg_gws.transit_gateways : x if x.name == "${var.vpc_name}-tg"]
}

# Condition 1: Transit Gateway Does Not Exist
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
  count      = local.tg == [] ? 1 : 0
  depends_on = [ibm_tg_gateway.mac_tg_gw]

  gateway      = ibm_tg_gateway.mac_tg_gw[0].id
  network_type = "vpc"
  name         = "${var.vpc_name}-vpc-conn"
  network_id   = data.ibm_is_vpc.vpc.resource_crn
}

# Condition 1: Transit Gateway Does Exists, so just update
# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection

# Check to see if the connection exists
data "ibm_tg_gateway" "existing_tg" {
  count = local.tg == [] ? 0 : 1
  name  = local.tg[0].name
}

locals {
  v_tg_conns = local.tg == [] ? [for x in data.ibm_tg_gateway.existing_tg[0].connections : x if x.name == "${var.vpc_name}-vc"] : []
}

resource "ibm_tg_connection" "vpc_tg_connection_update" {
  count = local.tg == [] && local.v_tg_conns == [] ? 0 : 1

  gateway      = local.tg[0].id
  network_type = "vpc"
  name         = "${var.vpc_name}-vc"
  network_id   = data.ibm_is_vpc.vpc.resource_crn
}