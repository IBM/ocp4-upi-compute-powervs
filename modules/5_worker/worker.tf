################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Dev Note: nop is a s
resource "null_resource" "nop" {
  triggers = {
    bastion_private_ip_mac = var.ignition_mac
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo "Waiting on DHCP Lease to be registered"
sleep 15
echo "Done waiting on DHCP Lease to be registered"
echo ""
echo "IP Information"
ip a

echo "Looking for mac: ${var.ignition_mac}"
EOF
    ]
  }
}

### Grab the Bastion Data
data "ibm_pi_dhcp" "refresh_dhcp_server" {
  depends_on           = [null_resource.nop]
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_dhcp_id           = var.powervs_dhcp_service.dhcp_id
}

data "ibm_pi_instance" "bastion_instance" {
  depends_on           = [data.ibm_pi_dhcp.refresh_dhcp_server]
  pi_instance_name     = var.powervs_bastion_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}

locals {
  # Dev Note: Leases should return the IP, however, they are returning empty in some data centers and existing workspaces.
  bastion_private_ip = [for lease in data.ibm_pi_dhcp.refresh_dhcp_server.leases : lease if lease.instance_mac == data.ibm_pi_instance.bastion_instance.networks[0].macaddress]
  ignition_ip        = length(var.ignition_ip) > 0 ? var.ignition_ip[0].instance_ip : local.bastion_private_ip[0].instance_ip
}

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  depends_on = [data.ibm_pi_dhcp.refresh_dhcp_server, null_resource.nop]

  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_instance_name     = "${var.name_prefix}-worker-${count.index}"

  pi_sys_type   = var.system_type
  pi_proc_type  = var.processor_type
  pi_memory     = var.worker["memory"]
  pi_processors = var.worker["processors"]
  pi_image_id   = var.rhcos_image_id

  pi_network {
    network_id = var.powervs_dhcp_network_id
  }

  pi_key_pair_name = var.key_name
  pi_health_status = "WARNING"

  # docs/development.md describes the worker.ign file
  pi_user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/5_worker/templates/worker.ign",
      {
        ignition_ip : "${local.ignition_ip}",
        name : base64encode("${var.name_prefix}-worker-${count.index}"),
  }))
}
