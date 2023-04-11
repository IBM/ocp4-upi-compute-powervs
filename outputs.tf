################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

output "worker_private_ip" {
  value = join(", ", data.ibm_pi_instance_ip.worker.*.ip)
}

output "worker_public_ip" {
  value = join(", ", data.ibm_pi_instance_ip.worker_public_ip.*.external_ip)
}

output "gateway_ip" {
  value = data.ibm_pi_network.network.gateway
}

output "cidr" {
  value = data.ibm_pi_network.network.cidr
}

output "public_cidr" {
  value = ibm_pi_network.public_network.pi_cidr
}