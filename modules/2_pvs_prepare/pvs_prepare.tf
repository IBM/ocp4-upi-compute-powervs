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

module "bastion" {
  providers = {
    ibm = ibm
  }
  depends_on = [module.images, module.keys]
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
  bastion_public_network_id       = ibm_pi_network.bastion_public_network.network_id
  bastion_public_network_cidr     = ibm_pi_network.bastion_public_network.pi_cidr
  bastion_public_network_name     = ibm_pi_network.bastion_public_network.pi_network_name
  powervs_network_id              = data.ibm_pi_network.private_network.id
  powervs_network_cidr            = var.powervs_machine_cidr
  private_key_file                = var.private_key_file
  public_key                      = module.keys.pvs_pubkey_name
  ssh_agent                       = var.ssh_agent
  connection_timeout              = var.connection_timeout
  cluster_domain                  = var.cluster_domain
  public_network_mtu              = var.public_network_mtu
  private_network_mtu             = var.private_network_mtu
  rhel_smt                        = var.rhel_smt
  rhel_username                   = var.rhel_username
  rhel_subscription_org           = var.rhel_subscription_org
  rhel_subscription_username      = var.rhel_subscription_username
  rhel_subscription_password      = var.rhel_subscription_password
  rhel_subscription_activationkey = var.rhel_subscription_activationkey
  vpc_support_server_ip           = var.vpc_support_server_ip
}

data "ibm_pi_cloud_instance" "pvs_cloud_instance" {
  pi_cloud_instance_id = var.powervs_service_instance_id
}