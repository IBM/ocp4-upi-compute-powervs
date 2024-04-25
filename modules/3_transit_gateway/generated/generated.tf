################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_tg_connection" "powervs_ibm_tg_connection" {
  gateway      = var.transit_gateway_id
  network_type = "power_virtual_server"
  name         = "${var.vpc_name}-pvs-conn"
  network_id   = var.powervs_crn

  lifecycle {
    ignore_changes = all
  }
}
