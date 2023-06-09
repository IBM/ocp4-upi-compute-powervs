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
  region           = var.powervs_region
  zone             = var.powervs_zone
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
  name_prefix = var.name_prefix == "" ? random_id.label[0].hex : "${var.name_prefix}"
  node_prefix = var.use_zone_info_for_names ? "${var.powervs_zone}-" : ""
}

### Prepares the VPC Support Machine
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
  override_region_check = var.override_region_check
}

### Prepares the VPC Support Machine
module "vpc_support" {
  providers = {
    ibm = ibm.vpc
  }
  depends_on = [module.checks]

  source            = "./modules/0_vpc_support"
  vpc_name          = var.vpc_name
  vpc_region        = var.vpc_region
  vpc_zone          = var.vpc_zone
  public_key        = var.public_key
  public_key_file   = var.public_key_file
  openshift_api_url = var.openshift_api_url
}

### Prepares the PowerVS workspace for Day-2 Workers
module "pvs_prepare" {
  providers = {
    ibm = ibm.powervs
  }
  source = "./modules/1_pvs_prepare"

  ansible_repo_name                  = var.ansible_repo_name
  bastion                            = var.bastion
  bastion_health_status              = var.bastion_health_status
  cloud_conn_name                    = var.cloud_conn_name
  cluster_domain                     = var.cluster_domain
  cluster_id                         = var.cluster_id
  connection_timeout                 = var.connection_timeout
  enable_snat                        = var.enable_snat
  powervs_machine_cidr               = var.powervs_machine_cidr
  name_prefix                        = var.name_prefix
  powervs_region                     = var.powervs_region
  powervs_service_instance_id        = var.powervs_service_instance_id
  private_key                        = var.private_key
  private_network_mtu                = var.private_network_mtu
  processor_type                     = var.processor_type
  powervs_dns_forwarders             = var.powervs_dns_forwarders == "" ? [] : [for dns in split(";", var.powervs_dns_forwarders) : trimspace(dns)]
  public_key                         = var.public_key
  powervs_network_name               = var.powervs_network_name
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
  vpc_crn                            = module.vpc_support.vpc_crn
  vpc_support_server_ip              = module.vpc_support.vpc_support_server_ip
}

module "support" {
  depends_on = [module.pvs_prepare]
  source     = "./modules/2_pvs_support"

  private_key_file         = var.private_key_file
  ssh_agent                = var.ssh_agent
  connection_timeout       = var.connection_timeout
  rhel_username            = var.rhel_username
  bastion_ip               = module.pvs_prepare.bastion_ip[0]
  bastion_public_ip        = module.pvs_prepare.bastion_public_ip[0]
  openshift_client_tarball = var.openshift_client_tarball
  openshift_api_url        = var.openshift_api_url
  vpc_support_server_ip    = module.vpc_support.vpc_support_server_ip
}

module "worker" {
  depends_on = [module.support]
  source     = "./modules/4_worker"

  bastion_ip             = module.pvs_prepare.bastion_ip[0]
  worker                 = var.worker
  rhcos_image_name       = var.rhcos_image_name
  service_instance_id    = var.powervs_service_instance_id
  system_type            = var.system_type
  public_key_name        = var.public_key_name
  processor_type         = var.processor_type
  name_prefix            = local.name_prefix
  powervs_network_name   = var.powervs_network_name
  powervs_dns_forwarders = var.powervs_dns_forwarders == "" ? [] : [for dns in split(";", var.powervs_dns_forwarders) : trimspace(dns)]

  # Eventually, this should be a bit more dynamic - include the MachineConfigPool
  ignition_url = "http://${module.pvs_prepare.bastion_ip[0]}:8080/worker.ign"
}

module "post" {
  depends_on = [module.worker]
  source     = "./modules/5_post"

  ssh_agent         = var.ssh_agent
  bastion_public_ip = module.pvs_prepare.bastion_public_ip
  private_key_file  = var.private_key_file
  ibmcloud_region   = var.vpc_region
  ibmcloud_zone     = var.vpc_zone
  system_type       = var.system_type
  nfs_server        = var.nfs_server
  nfs_path          = var.nfs_path
}
