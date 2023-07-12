################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

module "images" {
  source = "./images"

  service_instance_id                = var.powervs_service_instance_id
  powervs_region                     = var.powervs_region
  rhel_image_name                    = var.rhel_image_name
  rhcos_image_name                   = var.rhcos_image_name
  rhcos_import_image                 = var.rhcos_import_image
  rhcos_import_image_filename        = var.rhcos_import_image_filename
  rhcos_import_image_storage_type    = var.rhcos_import_image_storage_type
  rhcos_import_image_region_override = var.rhcos_import_image_region_override
}

module "keys" {
  source = "./keys"

  service_instance_id = var.powervs_service_instance_id
  name_prefix         = var.name_prefix
  public_key          = var.public_key
}

module "network" {
  source = "./network"

  service_instance_id = var.powervs_service_instance_id
  name_prefix         = var.name_prefix
  pub_network_dns     = var.pub_network_dns
  pvs_network_name    = var.pvs_network_name
  machine_cidr        = var.machine_cidr
  vpc_dns_server      = var.vpc_dns_server
  enable_snat         = var.enable_snat
  cluster_id          = var.cluster_id
  cloud_conn_name     = var.cloud_conn_name
  vpc_crn             = var.vpc_crn
}

module "bastion" {
  depends_on = [module.images, module.keys, module.network]
  source     = "./bastion"

  service_instance_id         = var.powervs_service_instance_id
  name_prefix                 = var.name_prefix
  bastion                     = var.bastion
  system_type                 = var.system_type
  processor_type              = var.processor_type
  bastion_health_status       = var.bastion_health_status
  bastion_image_id            = module.images.bastion_image_id
  bastion_storage_pool        = module.images.bastion_storage_pool
  key_name                    = module.keys.pvs_pubkey_name
  bastion_public_network_id   = module.network.bastion_public_network_id
  bastion_public_network_name = module.network.bastion_public_network_name
  powervs_dhcp_network_id     = module.network.powervs_dhcp_network_id
  powervs_dhcp_network_name   = module.network.powervs_dhcp_network_name

  private_key = var.private_key
  ssh_agent = var.ssh_agent
  connection_timeout = var.connection_timeout
  cluster_domain = var.cluster_domain
  private_network_mtu = var.private_network_mtu

  ansible_repo_name = var.ansible_repo_name
  rhel_username = var.rhel_username
  rhel_subscription_org = var.rhel_subscription_org
  rhel_subscription_username = var.rhel_subscription_username
  rhel_subscription_password = var.rhel_subscription_password


}