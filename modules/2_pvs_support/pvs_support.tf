################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  helpernode_vars = {
    cluster_domain    = var.cluster_domain
    name_prefix       = var.name_prefix
    cluster_id        = var.cluster_id
    name_prefix       = var.name_prefix
    bastion_ip        = var.bastion_ip
    bastion_name      = "${var.name_prefix}-bastion-0"
    isHA              = false
    bastion_master_ip = var.bastion_ip
    bastion_backup_ip = []
    forwarders        = var.vpc_dns_forwarders
    # Might have to force this to SNAT which uses var.bastion_ip[0]
    gateway_ip      = var.gateway_ip
    netmask         = cidrnetmask(var.cidr)
    broadcast       = cidrhost(var.cidr, -1)
    ipid            = cidrhost(var.cidr, 0)
    pool            = { "start" : cidrhost(var.cidr, 2), "end" : cidrhost(var.cidr, -2) }
    client_tarball  = var.openshift_client_tarball
    install_tarball = var.openshift_install_tarball
  }

  helpernode_inventory = {
    rhel_username = var.rhel_username
    bastion_ip    = var.bastion_ip
  }
}

resource "null_resource" "config" {
  triggers = {
    version = var.ansible_support_version
  }

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip[0]
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [
      "rm -rf /root/ocp4-upi-compute-powervs",
      "mkdir -p .openshift",
      "mkdir -p /root/ocp4-upi-compute-powervs"
    ]
  }

  # Copies the ansible/support to specific folder
  provisioner "file" {
    source      = "ansible/support"
    destination = "/root/ocp4-upi-compute-powervs/support/"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/helpernode_inventory", local.helpernode_inventory)
    destination = "ocp4-upi-compute-powervs/support/inventory"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/helpernode_vars.yaml", local.helpernode_vars)
    destination = "ocp4-upi-compute-powervs/support/helpernode_vars.yaml"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo 'Running ocp4-upi-compute-powervs playbook...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @helpernode_vars.yaml tasks/main.yml --become
EOF
    ]
  }
}
