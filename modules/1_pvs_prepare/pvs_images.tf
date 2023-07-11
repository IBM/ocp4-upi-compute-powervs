################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Based on https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/main/ocp.tf 
locals {
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
  rhcos_import_bucket_region = lookup(local.powervs_vpc_region_map, var.vpc_region, "au-syd")
}

# RHCOS Image Import
resource "ibm_pi_image" "rhcos_image_import" {
  count = var.rhcos_import_image ? 1 : 0

  pi_image_name             = "${var.name_prefix}rhcos-${var.rhcos_import_image_storage_type}-image"
  pi_cloud_instance_id      = var.service_instance_id
  pi_image_bucket_name      = "rhcos-powervs-images-${local.rhcos_import_bucket_region}"
  pi_image_bucket_region    = local.rhcos_import_bucket_region
  pi_image_bucket_file_name = var.rhcos_import_image_filename
  pi_image_storage_type     = var.rhcos_import_image_storage_type
}

data "ibm_pi_image" "rhcos" {
  depends_on = [ibm_pi_image.rhcos_image_import]

  pi_image_name        = var.rhcos_import_image ? ibm_pi_image.rhcos_image_import[0].pi_image_name : var.rhcos_image_name
  pi_cloud_instance_id = var.service_instance_id
}