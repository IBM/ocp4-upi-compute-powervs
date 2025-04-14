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
  # Dev note: The code originally used 9000, we've opted to configure lower
  pi_network_mtu = var.public_network_mtu
  # Dev Note: There appears to be an issue when 2 dns providers are passed in.connection {
  # Opting to leave commented out for now, as it is implicitly using 9.9.9.9

  lifecycle {
    ignore_changes = all
  }
}

# Dev Note: injects a delay the network create/destroy.
# Othweriwse, this message comes up: One or more ports have an IP allocation from this subnet.
resource "time_sleep" "wait_dhcp" {
  depends_on       = [ibm_pi_network.bastion_public_network]
  destroy_duration = "120s"
}

# The 3rd IP in this new network will be reserved for the bastion, and fixed.
resource "ibm_pi_dhcp" "new_dhcp_service" {
  depends_on           = [time_sleep.wait_dhcp]
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_cidr              = var.powervs_machine_cidr
  pi_dns_server        = var.vpc_support_server_ip
  pi_dhcp_snat_enabled = var.enable_snat
  # the pi_dhcp_name param will be prefixed by the DHCP ID when created, so keep it short here:
  pi_dhcp_name = var.cluster_id

  lifecycle {
    ignore_changes = all
  }
}

# Dev Note: injects a delay the dhcp_service/destroy.
# Othweriwse, this message comes up: Error: failed to perform Delete DHCP Operation for dhcp id
resource "time_sleep" "wait_dhcp_service_destroy" {
  depends_on       = [ibm_pi_dhcp.new_dhcp_service]
  destroy_duration = "120s"
}
