################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

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

data "ibm_pi_network" "private_network" {
  pi_network_name      = var.powervs_network_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}