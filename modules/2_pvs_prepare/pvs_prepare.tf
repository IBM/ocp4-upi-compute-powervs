################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

module "images" {
  providers = {
    ibm = ibm
  }
  source = "./images"

  powervs_service_instance_id        = var.powervs_service_instance_id
  powervs_region                     = var.powervs_region
  rhel_image_name                    = var.rhel_image_name
  rhcos_image_name                   = var.rhcos_image_name
  rhcos_import_image                 = var.rhcos_import_image
  rhcos_import_image_filename        = var.rhcos_import_image_filename
  rhcos_import_image_storage_type    = var.rhcos_import_image_storage_type
  rhcos_import_image_region_override = var.rhcos_import_image_region_override
  name_prefix                        = var.name_prefix
}

module "keys" {
  providers = {
    ibm = ibm
  }
  source = "./keys"

  powervs_service_instance_id = var.powervs_service_instance_id
  name_prefix                 = var.name_prefix
  public_key_file             = var.public_key_file
}

module "existing_network" {
  count = var.override_network_name == "" ? 0 : var.use_fixed_network ? 0 : 1
  providers = {
    ibm = ibm
  }
  source = "./existing_network"

  powervs_service_instance_id = var.powervs_service_instance_id
  name_prefix                 = var.name_prefix
  override_network_name       = var.override_network_name
}

module "network" {
  count = var.override_network_name == "" && !var.use_fixed_network ? 1 : 0
  providers = {
    ibm = ibm
  }
  source = "./network"

  powervs_service_instance_id = var.powervs_service_instance_id
  name_prefix                 = var.name_prefix
  powervs_machine_cidr        = var.powervs_machine_cidr
  vpc_support_server_ip       = var.vpc_support_server_ip
  enable_snat                 = var.enable_snat
  cluster_id                  = var.cluster_id
}

module "fixed_network" {
  count = var.use_fixed_network ? 1 : 0
  providers = {
    ibm = ibm
  }
  source = "./fixed_network"

  powervs_service_instance_id = var.powervs_service_instance_id
  cluster_id                  = var.cluster_id
  name_prefix                 = var.name_prefix
  powervs_machine_cidr        = var.powervs_machine_cidr
  vpc_support_server_ip       = var.vpc_support_server_ip
}

module "bastion" {
  providers = {
    ibm = ibm
  }
  depends_on = [module.images, module.keys, module.network, module.existing_network, module.fixed_network]
  source     = "./bastion"

  powervs_service_instance_id     = var.powervs_service_instance_id
  name_prefix                     = var.name_prefix
  bastion                         = var.bastion
  system_type                     = var.system_type
  processor_type                  = var.processor_type
  bastion_health_status           = var.bastion_health_status
  bastion_image_id                = module.images.bastion_image_id
  bastion_storage_pool            = module.images.bastion_storage_pool
  key_name                        = module.keys.pvs_pubkey_name
  bastion_public_network_id       = var.use_fixed_network ? module.fixed_network[0].bastion_public_network_id : var.override_network_name != "" ? module.existing_network[0].bastion_public_network_id : module.network[0].bastion_public_network_id
  bastion_public_network_name     = var.use_fixed_network ? module.fixed_network[0].bastion_public_network_name : var.override_network_name != "" ? module.existing_network[0].bastion_public_network_name : module.network[0].bastion_public_network_name
  bastion_public_network_cidr     = var.use_fixed_network ? module.fixed_network[0].bastion_public_network_cidr : var.override_network_name != "" ? module.existing_network[0].bastion_public_network_cidr : module.network[0].bastion_public_network_cidr
  powervs_network_id              = var.use_fixed_network ? module.fixed_network[0].powervs_network_id : var.override_network_name != "" ? module.existing_network[0].powervs_dhcp_network_id : module.network[0].powervs_dhcp_network_id
  powervs_network_name            = var.use_fixed_network ? module.fixed_network[0].powervs_network_name : var.override_network_name != "" ? module.existing_network[0].powervs_dhcp_network_name : module.network[0].powervs_dhcp_network_name
  powervs_network_cidr            = var.powervs_machine_cidr
  private_key_file                = var.private_key_file
  public_key                      = module.keys.pvs_pubkey_name
  ssh_agent                       = var.ssh_agent
  connection_timeout              = var.connection_timeout
  cluster_domain                  = var.cluster_domain
  private_network_mtu             = var.private_network_mtu
  ansible_repo_name               = var.ansible_repo_name
  rhel_smt                        = var.rhel_smt
  rhel_username                   = var.rhel_username
  rhel_subscription_org           = var.rhel_subscription_org
  rhel_subscription_username      = var.rhel_subscription_username
  rhel_subscription_password      = var.rhel_subscription_password
  rhel_subscription_activationkey = var.rhel_subscription_activationkey
  use_fixed_network               = var.use_fixed_network
  vpc_support_server_ip           = var.vpc_support_server_ip
}

data "ibm_pi_cloud_instance" "pvs_cloud_instance" {
  pi_cloud_instance_id = var.powervs_service_instance_id
}