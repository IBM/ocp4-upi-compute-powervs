################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

resource "null_resource" "post_kubeconfig" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
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
    destination = "/root/ocp4-upi-compute-powervs/post/"
  }
}

#command to run ansible playbook on Bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.post_kubeconfig]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  #command to run ansible playbook on Bastion
  provisioner "remote-exec" {
    inline = [
      "echo Running ansible-playbook for Post Activities",
      "cd /root/ocp4-upi-compute-powervs/post",
      "ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-post.log ansible-playbook tasks/main.yml"
    ]
  }
}
