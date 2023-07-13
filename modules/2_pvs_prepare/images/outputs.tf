################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_image_id" {
  description = "The PowerVS Centos/RHEL Image Id"
  value       = data.ibm_pi_image.bastion[0].id
}

output "rhcos_image_id" {
  description = "The PowerVS RHCOS Image Id"
  value       = data.ibm_pi_image.rhcos.id
}

output "rhcos_image_name" {
  description = "The PowerVS RHCOS Image Name"
  value       = data.ibm_pi_image.rhcos.pi_image_name
}

output "bastion_storage_pool" {
  description = "The PowerVS Storage Pool for the Image"
  value       = local.bastion_storage_pool
}