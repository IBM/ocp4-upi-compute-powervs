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
      region = "dal10",
      zone   = "dal"
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
    ca-mon = {
      region = "mon",
      zone   = "mon01"
    },
    eu-de = {
      region = "eu-de",
      zone   = "eu-de-1"
    },
    eu-gb = {
      region = "lon",
      zone   = "lon06"
    },
    eu-es = {
      region = "mad",
      zone   = "mad02"
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
  # Certain regions don't have a good mapping
  no_overlap_map_pvs_vpc = {
    eu-gb = {
      region = "lon",
    }
  }

  powervs_region = "${var.powervs_region}" != "" ? "${var.powervs_region}" : lookup(local.vpc_pvs, var.vpc_region, { region = "syd" }).region
  powervs_zone   = "${var.powervs_zone}" != "" ? "${var.powervs_zone}" : lookup(local.vpc_pvs, var.vpc_region, { zone = "syd05" }).zone

  # Logic to confirm the region check under various configurations is valid.
  # Dev Note: we did the mapping, so short circuit.
  empty_powervs_region = "${var.powervs_region}" == "" && "${var.powervs_zone}" == ""
  # Dev Note: match the VPC_region, it should not be empty
  region_name_overlap = length(regexall("${local.powervs_region}", "${var.vpc_region}")) > 0
  # Dev Note: eu-gb doesn't have a great overlap with regions, so we have a map incase there is more than one of these.
  no_overlap    = "${var.powervs_region}" != "" ? "${var.powervs_region}" : lookup(local.no_overlap_map_pvs_vpc, var.vpc_region, { zone = "falseX" }).region
  no_overlap_ok = local.no_overlap == "${var.powervs_region}"
  # Dev Note: since the expression is complicated we've broken it down to separate steps
  should_skip_region_check = var.override_region_check || local.empty_powervs_region || local.region_name_overlap || local.no_overlap_ok
}

data "ibm_is_vpc" "ibm_is_vpc" {
  name = var.vpc_name

  lifecycle {
    # Confirms the PVS/VPC regions are compatible.
    postcondition {
      condition     = local.should_skip_region_check
      error_message = "ERROR: Kindly confirm VPC region - ${var.vpc_region} and PowerVS region - ${var.powervs_region} are compatible"
    }
  }
}
