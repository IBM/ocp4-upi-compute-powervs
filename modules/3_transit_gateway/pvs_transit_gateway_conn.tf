################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

data "ibm_dl_gateway" "pvs_dl" {
  name = var.cloud_conn_name == "" ? "cloud-conn-${var.cluster_id}" : var.cloud_conn_name
}

resource "ibm_tg_connection" "powervs_ibm_tg_connection" {
  gateway      = var.transit_gateway_id.id
  network_type = "directlink"
  name         = "${var.vpc_name}-pvs-conn"
  network_id   = data.ibm_dl_gateway.pvs_dl.crn
}

# Ref: https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/tg_gateway
data "ibm_tg_gateway" "mac_tg_gw" {
  name = "${var.vpc_name}-tg"
}