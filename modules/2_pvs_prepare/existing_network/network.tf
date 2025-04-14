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
  pi_network_mtu       = var.public_network_mtu
  # Dev Note: There appears to be an issue when 2 dns providers are passed in.connection {
  # Opting to leave commented out for now, as it is implicitly using 9.9.9.9

  lifecycle {
    ignore_changes = all
  }
}

data "ibm_pi_dhcps" "dhcps" {
  pi_cloud_instance_id = var.powervs_service_instance_id
}

data "ibm_pi_dhcp" "dhcp" {
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_dhcp_id           = data.ibm_pi_dhcps.dhcps.servers[0].dhcp_id
}

locals {
  # Dev Note: in the future, we can use a count on line 22, and
  # process through the tuple to find the right dhcp server
  # making the assumption there is only one per workspace.
  # #[for server in data.ibm_pi_dhcps.dhcps.servers : server if server.network_name == "${var.override_network_name}"]
  server = data.ibm_pi_dhcp.dhcp
}
