################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Condition 1: Transit Gateway Does Exists
# Add the VPC to the existing gateway
# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection

# Loads the asserted transit gateway
data "ibm_tg_gateway" "existing_tg" {
  name = var.override_transit_gateway_name
}

# Dev Note: loads an existing transit gateway
resource "ibm_tg_connection" "vpc_tg_connection_update" {
  gateway      = data.ibm_tg_gateway.existing_tg.id
  network_type = "vpc"
  name         = "${var.vpc_name}-conn"
  network_id   = var.resource_crn
}