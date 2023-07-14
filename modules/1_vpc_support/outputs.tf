################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

output "vpc_support_server_ip" {
  value = ibm_is_instance.supp_vm_vsi[0].primary_network_interface[0].primary_ip.0.address
}

output "vpc_crn" {
  value = data.ibm_is_vpc.vpc.crn
}