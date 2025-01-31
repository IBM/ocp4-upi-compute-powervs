################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_support_server_ip" {
  value = module.vsi.vpc_support_server_ip
}

output "vpc_crn" {
  value = data.ibm_is_vpc.vpc.crn
}

output "vpc_resource_group" {
  value = data.ibm_is_vpc.vpc.resource_group
}

output "transit_gateway_id" {
  value = var.setup_transit_gateway ? module.transit_gateway[0].new_tg : module.existing_gateway[0].existing_tg
}

output "transit_gateway_name" {
  value = !var.setup_transit_gateway ? module.existing_gateway[0].existing_tg_name : module.transit_gateway[0].new_tg_name
}

output "transit_gateway_status" {
  value = !var.setup_transit_gateway ? module.existing_gateway[0].existing_tg_status : module.transit_gateway[0].new_tg_status
}

// Output could be more than one 
output "load_balancer_ips" {
  value = local.load_balancer_ips
}