################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_pi_network" "bastion_public_network" {
  pi_network_name      = "${var.name_prefix}-pub-net"
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_network_type      = "pub-vlan"
  pi_dns               = var.powervs_dns_forwarders
}

# Following the IPI IBM Cloud method
# Source: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/power_network/pi_network.tf

locals {
  ids               = data.ibm_pi_dhcps.dhcp_services.servers[*].dhcp_id
  names             = data.ibm_pi_dhcps.dhcp_services.servers[*].network_name
  dhcp_id_from_name = var.powervs_network_name == "" ? "" : matchkeys(local.ids, local.names, [var.powervs_network_name])[0]
}

data "ibm_pi_dhcps" "dhcp_services" {
  pi_cloud_instance_id = var.powervs_service_instance_id
}

resource "ibm_pi_dhcp" "new_dhcp_service" {
  count                  = var.powervs_network_name == "" ? 1 : 0
  pi_cloud_instance_id   = var.powervs_service_instance_id
  pi_cloud_connection_id = data.ibm_pi_cloud_connection.cloud_connection.id
  pi_cidr                = var.powervs_machine_cidr
  pi_dns_server          = var.vpc_support_server_ip
  pi_dhcp_snat_enabled   = var.enable_snat
  # the pi_dhcp_name param will be prefixed by the DHCP ID when created, so keep it short here:
  pi_dhcp_name = var.cluster_id
}

resource "ibm_pi_cloud_connection" "new_cloud_connection" {
  count                              = var.cloud_conn_name == "" ? 1 : 0
  pi_cloud_instance_id               = var.powervs_service_instance_id
  pi_cloud_connection_name           = "cloud-con-${var.cluster_id}"
  pi_cloud_connection_speed          = 100
  pi_cloud_connection_global_routing = true
  # Dev Note: Preference for Transit Gateway.
  #pi_cloud_connection_vpc_enabled    = true
  #pi_cloud_connection_vpc_crns       = [var.vpc_crn]
}

data "ibm_pi_cloud_connection" "cloud_connection" {
  pi_cloud_instance_id     = var.powervs_service_instance_id
  pi_cloud_connection_name = var.cloud_conn_name == "" ? ibm_pi_cloud_connection.new_cloud_connection[0].pi_cloud_connection_name : var.cloud_conn_name
}

data "ibm_pi_dhcp" "dhcp_service" {
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_dhcp_id           = var.powervs_network_name == "" ? ibm_pi_dhcp.new_dhcp_service[0].dhcp_id : local.dhcp_id_from_name
}
