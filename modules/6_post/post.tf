################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs/post"
  ansible_vars = {
    region      = var.powervs_region
    zone        = var.powervs_zone
    system_type = var.system_type
    nfs_server  = var.nfs_server
    nfs_path    = var.nfs_path
  }
}

resource "null_resource" "post_setup" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip[0]
    agent       = var.ssh_agent
  }

  #copies the ansible/post to specific folder
  provisioner "file" {
    source      = "ansible/post"
    destination = "${local.ansible_post_path}/"
  }
}

#command to run ansible playbook on Bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.post_setup]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip[0]
    agent       = var.ssh_agent
  }

  #create ansible_post_vars.json file on bastion (with desired variables to be passed to Ansible from Terraform)
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

# Dev Note: only on destroy - remove the worker
resource "null_resource" "destroy_worker" {
  depends_on = [null_resource.post_ansible]

  triggers = {
    count                 = var.worker["count"]
    name_prefix           = "${var.name_prefix}"
    vpc_support_server_ip = "${var.nfs_server}"
    private_key           = file(var.private_key_file)
    host                  = var.bastion_public_ip[0]
    agent                 = var.ssh_agent
    ansible_post_path     = local.ansible_post_path
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = self.triggers.private_key
    host        = self.triggers.host
    agent       = self.triggers.agent
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [<<EOF
cd ${self.triggers.ansible_post_path}
bash destroy-workers.sh "${self.triggers.count}" "${self.triggers.vpc_support_server_ip}" "${self.triggers.name_prefix}"
EOF
    ]
  }
}

resource "null_resource" "debug_taints" {
  depends_on = [null_resource.destroy_worker]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip[0]
    agent       = var.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.nfs_server}:3128"
oc get nodes -owide
oc get nodes -l 'kubernetes.io/arch=ppc64le' -o yaml | yq -r '.items[].spec'
EOF
    ]
  }
}