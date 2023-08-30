################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# *Bastion*
# Checks the image catalog to see if the image name exists and extracts the id
data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = var.powervs_service_instance_id
}

locals {
  catalog_bastion_image = [for x in data.ibm_pi_catalog_images.catalog_images.images : x if x.name == var.rhel_image_name || x.name == "rhcos-${var.rhcos_import_image_storage_type}-image"]
  bastion_image_id      = length(local.catalog_bastion_image) == 0 ? data.ibm_pi_image.bastion[0].id : local.catalog_bastion_image[0].image_id
  bastion_storage_pool  = length(local.catalog_bastion_image) == 0 ? data.ibm_pi_image.bastion[0].storage_pool : local.catalog_bastion_image[0].storage_pool
}

data "ibm_pi_image" "bastion" {
  count                = 1
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_image_name        = var.rhel_image_name
}

# Only run if we expect the image to exist.
data "ibm_pi_image" "rhcos_check" {
  count                = var.rhcos_import_image ? 0 : 1
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_image_name        = var.rhcos_image_name
}

# *RHCOS*
# Image Import
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
    mon     = "ca-tor"
  }
  # If not Empty, then we switch to using the override region
  rhcos_import_bucket_region = var.rhcos_import_image_region_override != "" ? "${var.rhcos_import_image_region_override}" : lookup(local.powervs_vpc_region_map, var.powervs_region, "au-syd")
}

# fix: Error: failed to perform Get Image Operation for image rhcos-tier1-image
resource "ibm_pi_image" "rhcos_image_import" {
  count = var.rhcos_import_image ? 1 : 0

  pi_cloud_instance_id      = var.powervs_service_instance_id
  pi_image_name             = "${var.name_prefix}-rhcos-${var.rhcos_import_image_storage_type}-image"
  pi_image_bucket_name      = "rhcos-powervs-images-${local.rhcos_import_bucket_region}"
  pi_image_bucket_region    = local.rhcos_import_bucket_region
  pi_image_bucket_file_name = var.rhcos_import_image_filename
  pi_image_storage_type     = var.rhcos_import_image_storage_type
}

data "ibm_pi_image" "rhcos" {
  depends_on = [ibm_pi_image.rhcos_image_import]

  pi_image_name        = data.ibm_pi_image.rhcos_check == [] && var.rhcos_import_image ? ibm_pi_image.rhcos_image_import[0].pi_image_name : var.rhcos_image_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}