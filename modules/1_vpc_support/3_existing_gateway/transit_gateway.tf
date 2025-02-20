################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Condition 1: Transit Gateway Does Exists
# Add the VPC to the existing gateway
# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/tg_connection

# Loads the asserted transit gateway
data "ibm_tg_gateway" "existing_tg" {
  name = var.transit_gateway_name
}