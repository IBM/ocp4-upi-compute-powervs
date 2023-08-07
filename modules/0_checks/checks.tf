################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Ref: VPC Regions https://cloud.ibm.com/docs/overview?topic=overview-locations
# Ref: PowerVS Regions https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-creating-power-virtual-server
# Ref: https://cluster-api-ibmcloud.sigs.k8s.io/reference/regions-zones-mapping.html

# If the PowerVS Region or Zone is empty, the code auto-populates the zone/region information
locals {
  vpc_pvs = {
    us-south = {
      region = "us-south",
      zone   = "us-south"
    },
    us-east = {
      region = "us-east",
      zone   = "us-east"
    },
    br-sao = {
      region = "sao",
      zone   = "sao01"
    },
    ca-tor = {
      region = "tor",
      zone   = "tor01"
    },
    eu-de = {
      region = "eu-de",
      zone   = "eu-de-1"
    },
    eu-gb = {
      region = "lon",
      zone   = "lon06"
    },
    au-syd = {
      region = "syd",
      zone   = "syd05"
    },
    jp-tok = {
      region = "tok",
      zone   = "tok04"
    },
    jp-osa = {
      region = "osa",
      zone   = "osa21"
    }
  }

  powervs_region = "${var.powervs_region}" != "" ? "${var.powervs_region}" : lookup(local.vpc_pvs, var.vpc_region, { region = "syd" }).region
  powervs_zone   = "${var.powervs_zone}" != "" ? "${var.powervs_zone}" : lookup(local.vpc_pvs, var.vpc_region, { zone = "syd05" }).zone

  # Finds the expected region
  expected_region = lookup(local.vpc_pvs, "${local.powervs_region}", { region = "syd" }).region
}

data "ibm_is_vpc" "ibm_is_vpc" {
  name = var.vpc_name

  lifecycle {
    # Confirms the PVS/VPC regions are compatible.
    postcondition {
      condition     = var.override_region_check || "${local.expected_region}" == "${local.powervs_region}" || length(regexall("${var.powervs_region}", "${var.vpc_region}")) > 0
      error_message = "ERROR: Kindly confirm VPC region - ${var.vpc_region} and PowerVS region - ${var.powervs_region} are compatible; false"
    }
  }
}
