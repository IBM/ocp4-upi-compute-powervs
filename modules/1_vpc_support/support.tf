################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Cross code dependencies

locals {
  public_key_file = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : "${path.cwd}/${var.public_key_file}"
  public_key      = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

module "keys" {
  providers = {
    ibm = ibm
  }
  source = "./0_keys"

  public_key_file = var.public_key_file
  resource_group  = data.ibm_is_vpc.vpc.resource_group
  vpc_name        = var.vpc_name
  public_key      = var.public_key
  skip_vpc_key    = var.skip_vpc_key
}

module "routes" {
  providers = {
    ibm = ibm
  }
  source = "./1_routes"

  vpc           = data.ibm_is_vpc.vpc.id
  routing_table = data.ibm_is_vpc.vpc.default_routing_table
  zone          = data.ibm_is_vpc.vpc.subnets[0].zone
  destination   = var.powervs_machine_cidr
}

module "security_groups" {
  providers = {
    ibm = ibm
  }
  source = "./2_security_groups"

  vpc                  = data.ibm_is_vpc.vpc.id
  vpc_name             = var.vpc_name
  powervs_machine_cidr = var.powervs_machine_cidr
  resource_group       = data.ibm_is_vpc.vpc.resource_group
}

module "existing_gateway" {
  count = var.setup_transit_gateway != true ? 1 : 0

  providers = {
    ibm = ibm
  }
  source = "./3_existing_gateway"

  setup_transit_gateway = var.setup_transit_gateway
  transit_gateway_name  = var.transit_gateway_name
  resource_crn          = data.ibm_is_vpc.vpc.resource_crn
  vpc_name              = var.vpc_name
  mac_tags              = var.mac_tags
}

module "transit_gateway" {
  count = var.setup_transit_gateway != true ? 0 : 1

  providers = {
    ibm = ibm
  }
  source = "./3_transit_gateway"

  setup_transit_gateway = var.setup_transit_gateway
  resource_crn          = data.ibm_is_vpc.vpc.resource_crn
  vpc_name              = var.vpc_name
  vpc_region            = var.vpc_region
  resource_group        = data.ibm_is_vpc.vpc.resource_group
  mac_tags              = var.mac_tags
}

module "vsi" {
  depends_on = [module.keys, module.security_groups]
  providers = {
    ibm = ibm
  }
  source = "./4_vsi"

  supp_vm_image_name = var.supp_vm_image_name
  vpc_name           = var.vpc_name
  vpc_id             = data.ibm_is_vpc.vpc.id
  zone               = data.ibm_is_vpc.vpc.subnets[0].zone
  resource_group     = data.ibm_is_vpc.vpc.resource_group
  subnet             = data.ibm_is_vpc.vpc.subnets[0].id
  vpc_region         = var.vpc_region
  vpc_supp_public_ip = var.vpc_supp_public_ip
  key_id             = module.keys.key_id
  sg_id              = module.security_groups.sg_id
  cp_internal_sg_id  = module.security_groups.cp_internal_sg_id
}
