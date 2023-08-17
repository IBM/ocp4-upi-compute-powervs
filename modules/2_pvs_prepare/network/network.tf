################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Following the IPI IBM Cloud method
# Source: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/power_network/pi_network.tf

resource "ibm_pi_network" "bastion_public_network" {
  pi_network_name      = "${var.name_prefix}-pub-net"
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_network_type      = "pub-vlan"
  # Dev Note: There appears to be an issue when 2 dns providers are passed in.connection {
  # Opting to leave commented out for now, as it is implicitly using 9.9.9.9
}

resource "time_sleep" "wait_3m_pubnet" {
  depends_on       = [ibm_pi_network.bastion_public_network]
  destroy_duration = "180s"
}

resource "ibm_pi_cloud_connection" "new_cloud_connection" {
  depends_on                          = [time_sleep.wait_3m_pubnet]
  count                               = 1
  pi_cloud_instance_id                = var.powervs_service_instance_id
  pi_cloud_connection_name            = "mac-cloud-conn-${var.cluster_id}"
  pi_cloud_connection_speed           = 1000
  pi_cloud_connection_global_routing  = true
  pi_cloud_connection_transit_enabled = true
  # Dev Note: Preference for Transit Gateway.
}

# Dev Note: injects a delay the network create/destroy.
# Othweriwse, this message comes up: One or more ports have an IP allocation from this subnet.
resource "time_sleep" "wait_dhcp" {
  depends_on       = [ibm_pi_cloud_connection.new_cloud_connection]
  create_duration  = "120s"
  destroy_duration = "120s"
}

data "ibm_pi_cloud_connection" "cloud_connection" {
  depends_on               = [time_sleep.wait_dhcp]
  pi_cloud_instance_id     = var.powervs_service_instance_id
  pi_cloud_connection_name = ibm_pi_cloud_connection.new_cloud_connection[0].pi_cloud_connection_name
}

resource "ibm_pi_dhcp" "new_dhcp_service" {
  depends_on             = [data.ibm_pi_cloud_connection.cloud_connection]
  pi_cloud_instance_id   = var.powervs_service_instance_id
  pi_cloud_connection_id = data.ibm_pi_cloud_connection.cloud_connection.id
  pi_cidr                = var.powervs_machine_cidr
  pi_dns_server          = var.vpc_support_server_ip
  pi_dhcp_snat_enabled   = var.enable_snat
  # the pi_dhcp_name param will be prefixed by the DHCP ID when created, so keep it short here:
  pi_dhcp_name = var.cluster_id
}

# Dev Note: injects a delay the dhcp_service/destroy.
# Othweriwse, this message comes up: Error: failed to perform Delete DHCP Operation for dhcp id
resource "time_sleep" "wait_dhcp_service_destroy" {
  depends_on       = [ibm_pi_dhcp.new_dhcp_service]
  destroy_duration = "120s"
}