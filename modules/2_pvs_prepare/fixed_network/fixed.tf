################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

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
  pi_dns               = [var.vpc_support_server_ip]
  pi_network_jumbo     = true
  # Dev Note: take the pi_gateway default
}
