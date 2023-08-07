################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  # The Inventory File
  helpernode_inventory = {
    rhel_username = var.rhel_username
  }

  # you must use the api-int url so the bastion routes over the correct interface.
  helpernode_vars = {
    client_tarball               = var.openshift_client_tarball
    openshift_machine_config_url = replace(replace(var.openshift_api_url, ":6443", ""), "://api.", "://api-int.")
    vpc_support_server_ip        = var.vpc_support_server_ip
  }

  cidrs = {
    cidrs_ipv4 = var.cidrs
  }
}

resource "null_resource" "kubeconfig" {
  count = fileexists(var.kubeconfig_file) ? 1 : 0
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.kube"
    ]
  }

  # Copies the kubeconfig to specific folder and replace api 
  provisioner "file" {
    content     = replace(file(var.kubeconfig_file), "://api.", "://api-int.")
    destination = "/root/.kube/config"
  }
}

resource "null_resource" "config" {
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
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
    content     = templatefile("${path.module}/templates/inventory.tpl", local.helpernode_inventory)
    destination = "ocp4-upi-compute-powervs/support/inventory"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/vars.yaml.tpl", local.helpernode_vars)
    destination = "ocp4-upi-compute-powervs/support/vars/vars.yaml"
  }

  # Copies the custom route for env3
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route-env3.tpl", local.cidrs)
    destination = "/etc/sysconfig/network-scripts/route-env3"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
ifup env3
echo 'Running ocp4-upi-compute-powervs playbook...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/main.yml --become
EOF
    ]
  }
}

# Two different paths to update the namespace.
resource "null_resource" "config_non" {
  count      = fileexists(var.kubeconfig_file) ? 0 : 1
  depends_on = [null_resource.config, null_resource.kubeconfig]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: Running the following should show you amd64
  # ❯ oc get ns openshift-cluster-csi-drivers -oyaml | yq -r '.metadata.annotations' | grep amd64
  # scheduler.alpha.kubernetes.io/node-selector: kubernetes.io/arch=amd64
  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc login \
  "${var.openshift_api_url}" -u "${var.openshift_user}" -p "${var.openshift_pass}" --insecure-skip-tls-verify=true
oc annotate ns openshift-cluster-csi-drivers \
  scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=amd64
EOF
    ]
  }
}

resource "null_resource" "config_kube" {
  count      = fileexists(var.kubeconfig_file) ? 1 : 0
  depends_on = [null_resource.config, null_resource.kubeconfig]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc annotate --kubeconfig /root/.kube/config ns openshift-cluster-csi-drivers \
  scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=amd64
EOF
    ]
  }
}

resource "null_resource" "adjust_mtu" {
  depends_on = [null_resource.config_kube, null_resource.config_non]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc patch Network.operator.openshift.io cluster --type=merge --patch \
  '{"spec": { "migration": { "mtu": { "network": { "from": 1400, "to": 9000 } , "machine": { "to" : 9100} } } } }'
EOF
    ]
  }
}

# The MTU change may take a few minutes
resource "time_sleep" "wait_5_minutes" {
  depends_on      = [null_resource.adjust_mtu]
  create_duration = "5m"
}

resource "null_resource" "wait_on_mcp" {
  depends_on = [time_sleep.wait_5_minutes]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc wait mcp/master --for condition=updated --timeout=30m
oc wait mcp/worker --for condition=updated --timeout=30m
EOF
    ]
  }
}