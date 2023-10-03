################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.vpc_region
  zone             = var.vpc_zone
  alias            = "vpc"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = module.checks.powervs_region
  zone             = module.checks.powervs_zone
  alias            = "powervs"
}

# Create a random_id label
resource "random_id" "label" {
  count       = 1
  byte_length = "2" # Since we use the hex, the word lenght would double
}

locals {
  cluster_id = var.cluster_id == "" ? random_id.label[0].hex : (var.cluster_id_prefix == "" ? var.cluster_id : "${var.cluster_id_prefix}-${var.cluster_id}")
  # Generates vm_id as combination of vm_id_prefix + (random_id or user-defined vm_id)
  name_prefix = var.name_prefix == "" ? "mac-${random_id.label[0].hex}" : "${var.name_prefix}"
  node_prefix = var.use_zone_info_for_names ? "${var.powervs_zone}-" : ""
}

### Checks VPC compatibility
module "checks" {
  providers = {
    ibm = ibm.vpc
  }
  source = "./modules/0_checks"

  ibmcloud_api_key      = var.ibmcloud_api_key
  vpc_name              = var.vpc_name
  vpc_region            = var.vpc_region
  vpc_zone              = var.vpc_zone
  powervs_region        = var.powervs_region
  powervs_zone          = var.powervs_zone
  override_region_check = var.override_region_check
}

### Prepares the VPC Support Machine
module "vpc_support" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.checks]
  source     = "./modules/1_vpc_support"

  vpc_name                      = var.vpc_name
  vpc_region                    = var.vpc_region
  vpc_zone                      = var.vpc_zone
  public_key                    = var.public_key
  public_key_file               = var.public_key_file
  openshift_api_url             = var.openshift_api_url
  powervs_machine_cidr          = var.powervs_machine_cidr
  vpc_supp_public_ip            = var.vpc_supp_public_ip
  override_transit_gateway_name = var.override_transit_gateway_name
  mac_tags                      = var.mac_tags
}

### Prepares the PowerVS workspace for Day-2 Workers
module "pvs_prepare" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.vpc_support]
  source     = "./modules/2_pvs_prepare"

  ansible_repo_name                  = var.ansible_repo_name
  bastion                            = var.bastion
  bastion_health_status              = var.bastion_health_status
  cluster_domain                     = var.cluster_domain
  cluster_id                         = local.cluster_id
  connection_timeout                 = var.connection_timeout
  enable_snat                        = var.enable_snat
  powervs_machine_cidr               = var.powervs_machine_cidr
  name_prefix                        = local.name_prefix
  powervs_region                     = module.checks.powervs_region
  powervs_zone                       = module.checks.powervs_zone
  powervs_service_instance_id        = var.powervs_service_instance_id
  private_key_file                   = var.private_key_file
  public_key_file                    = var.public_key_file
  private_network_mtu                = var.private_network_mtu
  processor_type                     = var.processor_type
  powervs_dns_forwarders             = var.powervs_dns_forwarders == "" ? [] : [for dns in split(";", var.powervs_dns_forwarders) : trimspace(dns)]
  public_key                         = var.public_key
  rhcos_image_name                   = var.rhcos_image_name
  rhcos_import_image                 = var.rhcos_import_image
  rhcos_import_image_filename        = var.rhcos_import_image_filename
  rhcos_import_image_region_override = var.rhcos_import_image_region_override
  rhcos_import_image_storage_type    = var.rhcos_import_image_storage_type
  rhel_image_name                    = var.rhel_image_name
  rhel_subscription_org              = var.rhel_subscription_org
  rhel_subscription_password         = var.rhel_subscription_password
  rhel_subscription_username         = var.rhel_subscription_username
  rhel_username                      = var.rhel_username
  rhel_subscription_activationkey    = var.rhel_subscription_activationkey
  rhel_smt                           = var.rhel_smt
  ssh_agent                          = var.ssh_agent
  system_type                        = var.system_type
  vpc_support_server_ip              = module.vpc_support.vpc_support_server_ip
  override_network_name              = var.override_network_name
  use_fixed_network                  = var.use_fixed_network
}

module "transit_gateway" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.pvs_prepare]
  source     = "./modules/3_transit_gateway"

  cluster_id                    = local.cluster_id
  vpc_name                      = var.vpc_name
  vpc_crn                       = module.vpc_support.vpc_crn
  transit_gateway_id            = module.vpc_support.transit_gateway_id
  override_transit_gateway_name = var.override_transit_gateway_name
  powervs_crn       = module.pvs_prepare.powervs_crn
}

module "support" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.transit_gateway]
  source     = "./modules/4_pvs_support"

  private_key_file         = var.private_key_file
  ssh_agent                = var.ssh_agent
  connection_timeout       = var.connection_timeout
  rhel_username            = var.rhel_username
  bastion_public_ip        = module.pvs_prepare.bastion_public_ip[0]
  openshift_client_tarball = var.openshift_client_tarball
  vpc_support_server_ip    = module.vpc_support.vpc_support_server_ip
  openshift_api_url        = var.openshift_api_url
  openshift_user           = var.openshift_user
  openshift_pass           = var.openshift_pass
  kubeconfig_file          = var.kubeconfig_file
  cidrs                    = module.transit_gateway.mac_vpc_subnets
  powervs_machine_cidr     = var.powervs_machine_cidr
  keep_dns                 = var.keep_dns
  worker                   = var.worker
  use_fixed_network        = var.use_fixed_network
}

module "worker" {
  providers = {
    ibm = ibm.powervs
  }
  depends_on = [module.support]
  source     = "./modules/5_worker"

  key_name                    = module.pvs_prepare.pvs_pubkey_name
  name_prefix                 = local.name_prefix
  powervs_service_instance_id = var.powervs_service_instance_id
  powervs_dhcp_network_id     = module.pvs_prepare.powervs_dhcp_network_id
  powervs_dhcp_network_name   = module.pvs_prepare.powervs_dhcp_network_name
  powervs_bastion_name        = module.pvs_prepare.powervs_bastion_name
  processor_type              = var.processor_type
  rhcos_image_id              = module.pvs_prepare.rhcos_image_id
  system_type                 = var.system_type
  worker                      = var.worker
  ignition_mac                = module.pvs_prepare.bastion_private_mac
  ignition_ip                 = module.worker.bastion_private_ip
  powervs_dhcp_service        = module.pvs_prepare.powervs_dhcp_service
  # Eventually, this should be a bit more dynamic and include MachineConfigPool

  private_key_file  = var.private_key_file
  ssh_agent         = var.ssh_agent
  bastion_public_ip = module.pvs_prepare.bastion_public_ip[0]
  use_fixed_network = var.use_fixed_network
}

module "post" {
  depends_on = [module.worker]
  source     = "./modules/6_post"

  ssh_agent         = var.ssh_agent
  bastion_public_ip = module.pvs_prepare.bastion_public_ip
  private_key_file  = var.private_key_file
  powervs_region    = module.checks.powervs_region
  powervs_zone      = module.checks.powervs_zone
  system_type       = var.system_type
  nfs_server        = module.vpc_support.vpc_support_server_ip
  nfs_path          = var.nfs_path
  name_prefix       = local.name_prefix
  worker            = var.worker
  cicd              = var.cicd
  openshift_api_url = var.openshift_api_url
  openshift_user    = var.openshift_user
  openshift_pass    = var.openshift_pass
}
