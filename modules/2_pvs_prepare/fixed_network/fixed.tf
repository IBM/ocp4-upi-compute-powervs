################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_pi_cloud_connection" "new_cloud_connection" {
  pi_cloud_instance_id                = var.powervs_service_instance_id
  pi_cloud_connection_name            = "mac-cloud-conn-${var.cluster_id}"
  pi_cloud_connection_speed           = 1000
  pi_cloud_connection_global_routing  = true
  pi_cloud_connection_transit_enabled = true
  # Dev Note: Preference for Transit Gateway.
}

resource "ibm_pi_network" "bastion_public_network" {
  pi_network_name      = "${var.name_prefix}-${var.cluster_id}-pub-net"
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_network_type      = "pub-vlan"
  # Dev Note: There appears to be an issue when 2 dns providers are passed in.connection {
  # Opting to leave commented out for now, as it is implicitly using 9.9.9.9
}

resource "ibm_pi_network" "fixed_network" {
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_network_name      = "${var.name_prefix}-${var.cluster_id}-priv-net"
  pi_network_type      = "vlan"
  pi_cidr              = var.powervs_machine_cidr
  pi_dns               = var.vpc_support_server_ip
  pi_network_jumbo     = true
  # Dev Note: take the pi_gateway default
}

# Dev Note: injects a delay the network create/destroy.
# Othweriwse, this message comes up: One or more ports have an IP allocation from this subnet.
resource "time_sleep" "wait_cc" {
  depends_on       = [ibm_pi_cloud_connection.new_cloud_connection, ibm_pi_network.fixed_network]
  create_duration  = "15s"
  destroy_duration = "120s"
}

# Attaches it back to the network
resource "ibm_pi_cloud_connection_network_attach" "add_cc_to_priv_net" {
  pi_cloud_instance_id   = var.powervs_service_instance_id
  pi_cloud_connection_id = ibm_pi_cloud_connection.new_cloud_connection.id
  pi_network_id          = ibm_pi_network.fixed_network.network_id
}