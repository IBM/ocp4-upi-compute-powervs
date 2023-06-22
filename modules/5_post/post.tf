################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs/post"
  ansible_vars = {
    region      = var.ibmcloud_region
    zone        = var.ibmcloud_zone
    system_type = var.system_type
  }
}

resource "null_resource" "post_kubeconfig" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip[0]
    agent       = var.ssh_agent
  }

  #create .kube directory
  provisioner "remote-exec" {
    inline = [
      "hostname",
      "mkdir -p /root/.kube"
    ]
  }

  #copy kubeconfig to Bastion
  provisioner "file" {
    source      = var.kubeconfig_file
    destination = "/root/.kube/config"
  }

  #copies the ansible/post to specific folder
  provisioner "file" {
    source      = "ansible/post"
    destination = "${local.ansible_post_path}/"
  }
}

#command to run ansible playbook on Bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.post_kubeconfig]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip[0]
    agent       = var.ssh_agent
  }

  #create ansible_post_vars.json file on bation with desired node_labels in it
  provisioner "file" {
    content     = templatefile("${path.module}/templates/ansible_post_vars.json.tpl", local.ansible_vars)
    destination = "${local.ansible_post_path}/ansible_post_vars.json"
  }

  #command to run ansible playbook on Bastion
  provisioner "remote-exec" {
    inline = [
      "echo Running ansible-playbook for Post Activities",
      "cd ${local.ansible_post_path}",
      "ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-post.log ansible-playbook tasks/main.yml --extra-vars @ansible_post_vars.json"
    ]
  }
}
