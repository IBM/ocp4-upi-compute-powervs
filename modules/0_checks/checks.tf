################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_is_vpc" "ibm_is_vpc" {
  name = var.vpc_name

  lifecycle {
    # Confirms the PVS/VPC regions are compatible.
    postcondition {
      condition     = var.override_region_check || length(regexall("${var.powervs_region}", "${var.vpc_region}")) > 0
      error_message = "ERROR: Kindly confirm VPC region - ${var.vpc_region} and PowerVS region - ${var.powervs_region} are compatible; false"
    }
  }
}
