################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.ibmcloud_region
  zone             = var.ibmcloud_zone
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
  node_prefix = var.use_zone_info_for_names ? "${var.ibmcloud_zone}-" : ""
}

### Prepares the Bastion Support machine
module "prepare" {
  source = "./modules/1_prepare"

  bastion                         = var.bastion
  service_instance_id             = var.service_instance_id
  cluster_id                      = local.cluster_id
  name_prefix                     = local.name_prefix
  node_prefix                     = local.node_prefix
  cluster_domain                  = var.cluster_domain
  rhel_image_name                 = var.rhel_image_name
  processor_type                  = var.processor_type
  system_type                     = var.system_type
  network_name                    = var.network_name
  network_dns                     = var.dns_forwarders == "" ? [] : [for dns in split(";", var.dns_forwarders) : trimspace(dns)]
  bastion_health_status           = var.bastion_health_status
  private_network_mtu             = var.private_network_mtu
  rhel_username                   = var.rhel_username
  private_key                     = local.private_key
  public_key                      = local.public_key
  ssh_agent                       = var.ssh_agent
  connection_timeout              = var.connection_timeout
  rhel_subscription_username      = var.rhel_subscription_username
  rhel_subscription_password      = var.rhel_subscription_password
  rhel_subscription_org           = var.rhel_subscription_org
  rhel_subscription_activationkey = var.rhel_subscription_activationkey
  ansible_repo_name               = var.ansible_repo_name
  rhel_smt                        = var.rhel_smt
}

module "support" {
  depends_on = [module.prepare]
  source     = "./modules/2_support"

  bastion_ip        = module.prepare.bastion_ip
  bastion_public_ip = module.prepare.bastion_public_ip
  gateway_ip        = module.prepare.gateway_ip
  cidr              = module.prepare.cidr
  cluster_domain    = var.cluster_domain
  cluster_id        = local.cluster_id
  name_prefix       = local.name_prefix
  node_prefix       = local.node_prefix

  rhel_username = var.rhel_username
  private_key   = local.private_key
  ssh_agent     = var.ssh_agent

  openshift_install_tarball = var.openshift_install_tarball
  openshift_client_tarball  = var.openshift_client_tarball
  pull_secret               = file(coalesce(var.pull_secret_file, "/dev/null"))
  ansible_support_version   = var.ansible_support_version

  connection_timeout = var.connection_timeout
}

module "worker" {
  depends_on = [module.support]
  source     = "./modules/4_worker"

  bastion_ip          = module.prepare.bastion_ip
  worker              = var.worker
  rhcos_image_name    = var.rhcos_image_name
  service_instance_id = var.service_instance_id
  network_name        = var.network_name
  system_type         = var.system_type
  public_key_name     = var.public_key_name
  processor_type      = var.processor_type
  name_prefix         = local.name_prefix

  workers_version = var.workers_version
}

module "post" {
  depends_on = [module.worker]
  source     = "./modules/5_post"

  ssh_agent         = var.ssh_agent
  bastion_public_ip = module.prepare.bastion_public_ip
  private_key_file  = var.private_key_file
  kubeconfig_file   = var.kubeconfig_file
}