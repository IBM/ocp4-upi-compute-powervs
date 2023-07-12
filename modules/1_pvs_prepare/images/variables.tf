################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# PVS
variable "powervs_region" {}
variable "service_instance_id" {}

# Bastion
variable "rhel_image_name" {}

### RHCOS
variable "rhcos_image_name" {}
variable "rhcos_import_image" {}
variable "rhcos_import_image_filename" {}
variable "rhcos_import_image_storage_type" {}

### Prerelease images are only in us-east
variable "rhcos_import_image_region_override" {}