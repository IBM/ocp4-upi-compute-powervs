################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ansible_post_path = "/root/ocp4-upi-compute-powervs/post"
  ansible_vars = {
    region             = var.powervs_region
    zone               = var.powervs_zone
    system_type        = var.system_type
    nfs_server         = var.nfs_server
    nfs_path           = var.nfs_path
    power_worker_count = var.worker["count"]
    power_prefix       = var.name_prefix
    cicd               = var.cicd
  }

  nfs_namespace  = "nfs-provisioner"
  nfs_deployment = "nfs-client-provisioner"
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

# Dev Note: only on destroy - remove the workers, and leave it at the top after post_setup
resource "null_resource" "remove_workers" {
  depends_on = [null_resource.post_setup]

  triggers = {
    #    count                 = var.worker["count"]
    name_prefix           = "${var.name_prefix}"
    vpc_support_server_ip = "${var.nfs_server}"
    private_key           = sensitive(file(var.private_key_file))
    host                  = var.bastion_public_ip[0]
    agent                 = var.ssh_agent
    ansible_post_path     = local.ansible_post_path
    openshift_api_url     = var.openshift_api_url
    openshift_user        = var.openshift_user
    openshift_pass        = var.openshift_pass
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
export HTTPS_PROXY="http://${self.triggers.vpc_support_server_ip}:3128"
oc login \
  "${self.triggers.openshift_api_url}" -u "${self.triggers.openshift_user}" -p "${self.triggers.openshift_pass}" --insecure-skip-tls-verify=true

cd ${self.triggers.ansible_post_path}
bash files/destroy-workers.sh "${self.triggers.vpc_support_server_ip}" "${self.triggers.name_prefix}"
EOF
    ]
  }
}

#command to run ansible playbook on Bastion
resource "null_resource" "post_ansible" {
  depends_on = [null_resource.remove_workers, null_resource.post_setup]

  triggers = {
    count       = var.worker["count"]
    name_prefix = "${var.name_prefix}"
  }

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

  provisioner "remote-exec" {
    inline = [<<EOF
cd ${local.ansible_post_path}
chmod +x files/approve_and_issue.sh
bash files/approve_and_issue.sh ${var.nfs_server} ${var.worker["count"]} ${var.name_prefix}
EOF
    ]
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

# Dev Note: Normal Cloud Providers remove this taint, we have to manually remove it.
# ref: https://github.com/openshift/kubernetes/blob/master/staging/src/k8s.io/cloud-provider/api/well_known_taints.go#L20
resource "null_resource" "debug_and_remove_taints" {
  depends_on = [null_resource.post_ansible]
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
echo "[All Nodes]"
oc get nodes -owide
echo "[Power Nodes]"
oc get nodes -l 'kubernetes.io/arch=ppc64le' -o json | jq -r '.items[]'
cd ${local.ansible_post_path}
bash files/remove-worker-taints.sh "${var.nfs_server}" "${var.name_prefix}" "${var.worker["count"]}"
EOF
    ]
  }
}

# Dev Note: only on destroy - remove the the deployment for nfs storage, and leave after post_ansible
resource "null_resource" "remove_nfs_deployment" {
  depends_on = [null_resource.post_ansible, null_resource.debug_and_remove_taints]

  triggers = {
    vpc_support_server_ip = "${var.nfs_server}"
    private_key           = sensitive(file(var.private_key_file))
    host                  = var.bastion_public_ip[0]
    agent                 = var.ssh_agent
    nfs_namespace         = local.nfs_namespace
    nfs_deployment        = local.nfs_deployment
    ansible_post_path     = local.ansible_post_path
    openshift_api_url     = var.openshift_api_url
    openshift_user        = var.openshift_user
    openshift_pass        = var.openshift_pass
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
export HTTPS_PROXY="http://${self.triggers.vpc_support_server_ip}:3128"
oc login \
  "${self.triggers.openshift_api_url}" -u "${self.triggers.openshift_user}" -p "${self.triggers.openshift_pass}" --insecure-skip-tls-verify=true

cd ${self.triggers.ansible_post_path}
bash files/destroy-nfs-deployment.sh "${self.triggers.nfs_deployment}" "${self.triggers.vpc_support_server_ip}" "${self.triggers.nfs_namespace}"
EOF
    ]
  }
}
