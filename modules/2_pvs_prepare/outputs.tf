################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "bastion_private_mac" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_private_mac
}

output "bastion_public_ip" {
  depends_on = [module.bastion]
  value      = module.bastion.bastion_public_ip
}

output "pvs_pubkey_name" {
  depends_on = [module.keys]
  value      = module.keys.pvs_pubkey_name
}

output "powervs_dhcp_network_id" {
  depends_on = [module.network]
  value      = var.override_network_name != "" ? module.existing_network[0].powervs_dhcp_network_id : module.network[0].powervs_dhcp_network_id
}

output "rhcos_image_id" {
  depends_on = [module.images]
  value      = module.images.rhcos_image_id
}

output "powervs_dhcp_service" {
  value = var.override_network_name != "" ? module.existing_network[0].powervs_dhcp_service.dhcp_id : module.network[0].powervs_dhcp_service.dhcp_id
}

output "powervs_bastion_name" {
  value = module.bastion.powervs_bastion_name
}

output "powervs_crn" {
  # Dev Note: generated pattern is as follows:
  # crn:v1:bluemix:public:power-iaas:<ZONE>:a/<TENANT_ID>:<SERVICE_INSTANCE_ID>::
  value = format("crn:v1:bluemix:public:power-iaas:%s:a/%s:%s::", var.powervs_zone, data.ibm_pi_cloud_instance.pvs_cloud_instance.tenant_id, var.powervs_service_instance_id)
}