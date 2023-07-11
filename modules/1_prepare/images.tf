################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Based on https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/main/ocp.tf 
locals {
  # Generates cluster_id as combination of cluster_id_prefix + (random_id or user-defined cluster_id)
  cluster_id   = var.cluster_id == "" ? random_id.label[0].hex : (var.cluster_id_prefix == "" ? var.cluster_id : "${var.cluster_id_prefix}-${var.cluster_id}")
  node_prefix  = var.use_zone_info_for_names ? "${var.ibmcloud_zone}-" : ""
  storage_type = lookup(var.bastion, "count", 1) > 1 ? "none" : var.storage_type
  powervs_vpc_region_map = {
    syd     = "au-syd",
    osa     = "jp-osa",
    tok     = "jp-tok",
    eu-de   = "eu-de",
    lon     = "eu-gb",
    tor     = "ca-tor",
    dal     = "us-south",
    sao     = "br-sao",
    us-east = "us-east"
  }
}

# RHCOS Image Import
resource "ibm_pi_image" "rhcos_image_import" {
  count = var.rhcos_import_image ? 1 : 0

  pi_image_name             = "${var.name_prefix}rhcos-${var.rhcos_import_image_storage_type}-image"
  pi_cloud_instance_id      = var.service_instance_id
  pi_image_bucket_name      = "rhcos-powervs-images-${var.rhcos_import_bucket_region}"
  pi_image_bucket_region    = var.rhcos_import_bucket_region
  pi_image_bucket_file_name = var.rhcos_import_image_filename
  pi_image_storage_type     = var.rhcos_import_image_storage_type
}

data "ibm_pi_image" "rhcos" {
  depends_on = [ibm_pi_image.rhcos_image_import]

  pi_image_name        = var.rhcos_import_image ? ibm_pi_image.rhcos_image_import[0].pi_image_name : var.rhcos_image_name
  pi_cloud_instance_id = var.service_instance_id
}