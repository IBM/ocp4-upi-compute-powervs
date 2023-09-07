################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_dl_gateway" "pvs_dl" {
  name = "mac-cloud-conn-${var.cluster_id}"
}

resource "ibm_tg_connection" "powervs_ibm_tg_connection" {
  gateway      = var.transit_gateway_id.id
  network_type = "directlink"
  name         = "${var.vpc_name}-pvs-conn"
  network_id   = data.ibm_dl_gateway.pvs_dl.crn
}