################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Condition 2: Transit Gateway Does Not Exist
# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_gateway
resource "ibm_tg_gateway" "mac_tg_gw" {
  name           = "${var.vpc_name}-tg"
  location       = var.vpc_region
  global         = false
  resource_group = var.resource_group
}

# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection
resource "ibm_tg_connection" "vpc_tg_connection" {
  depends_on = [ibm_tg_gateway.mac_tg_gw]

  gateway      = ibm_tg_gateway.mac_tg_gw.id
  network_type = "vpc"
  name         = "${var.vpc_name}-vpc-conn"
  network_id   = var.resource_crn
}

resource "ibm_resource_tag" "tag" {
  resource_id = ibm_tg_gateway.mac_tg_gw.crn
  tags        = var.mac_tags
}