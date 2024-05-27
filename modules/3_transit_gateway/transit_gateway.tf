################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

module "generated" {
  count = var.setup_transit_gateway ? 1 : 0
  providers = {
    ibm = ibm
  }
  source = "./generated"

  cluster_id         = var.cluster_id
  transit_gateway_id = var.transit_gateway_id
  vpc_name           = var.vpc_name
  powervs_crn        = var.powervs_crn
}

module "subnets" {
  providers = {
    ibm = ibm
  }
  source = "./subnets"

  vpc_name = var.vpc_name
}
