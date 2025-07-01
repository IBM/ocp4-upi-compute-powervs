################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  # The Inventory File
  helpernode_inventory = {
    rhel_username = var.rhel_username
  }

  worker_hosts = flatten([for k, v in range(var.worker["count"]) :
    [
      for t in range(v) : cidrhost(var.powervs_machine_cidr, 2 + k)
    ]
  ])

  openshift_machine_config_url = replace(replace(var.openshift_api_url, ":6443", ""), "://api.", "://api-int.")

  # you must use the api-int url so the bastion routes over the correct interface.
  helpernode_vars = {
    client_tarball               = var.openshift_client_tarball
    openshift_machine_config_url = local.openshift_machine_config_url
    vpc_support_server_ip        = var.vpc_support_server_ip
    power_worker_count           = var.worker["count"]
    nfs_server                   = var.nfs_server
    nfs_path                     = var.nfs_path
    cicd                         = var.cicd
  }

  cidrs = {
    cidrs_ipv4 = var.cidrs
    gateway    = cidrhost(var.powervs_machine_cidr, 1)
    subnet     = var.powervs_machine_cidr
  }

  cidr_str = split("/", var.powervs_machine_cidr)[0]
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
    // Change to api. - replace is left so we can easily revert
    content     = replace(file(var.kubeconfig_file), "://api.", "://api.")
    destination = "/root/.kube/config"
  }
}

resource "null_resource" "config" {
  depends_on = [null_resource.kubeconfig]
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
    content     = templatefile("${path.module}/templates/inventory.tftpl", local.helpernode_inventory)
    destination = "ocp4-upi-compute-powervs/support/inventory"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/vars.yaml.tftpl", local.helpernode_vars)
    destination = "ocp4-upi-compute-powervs/support/vars/vars.yaml"
  }

  # Copies the custom route script
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route-env.sh.tftpl", local.cidrs)
    destination = "ocp4-upi-compute-powervs/support/route-env.sh"
  }

  # Dev Note: need to move the route script to the right location
  provisioner "remote-exec" {
    inline = [<<EOF
cd ocp4-upi-compute-powervs/support
chmod +x ./route-env.sh
./route-env.sh 

echo 'Running ocp4-upi-compute-powervs playbook...'
mkdir -p /root/.openshift
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/main.yml --become
EOF
    ]
  }
}

# Dev Note: login
resource "null_resource" "config_login" {
  count      = fileexists(var.kubeconfig_file) ? 0 : 1
  depends_on = [null_resource.config]
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
oc login "${var.openshift_api_url}" -u "${var.openshift_user}" -p "${var.openshift_pass}" --insecure-skip-tls-verify=true
EOF
    ]
  }
}

# Dev Note: disable etcd defragmentation using flag cicd_disable_defrag
resource "null_resource" "disable_etcd_defrag" {
  depends_on = [null_resource.config_login, null_resource.config]
  count      = var.cicd_disable_defrag ? 1 : 0
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
outval=$(oc get configmap etcd-disable-defrag -n openshift-etcd-operator)
if [ -z "$outval" ]
then
  oc create configmap etcd-disable-defrag -n openshift-etcd-operator
else
  echo "configmap etcd-disable-defrag already exists"
fi
EOF
    ]
  }
}

# Dev Note: setup nfs deployment
resource "null_resource" "nfs_deployment" {
  depends_on = [null_resource.config_login, null_resource.config]
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
echo 'Running ocp4-upi-compute-powervs playbook...'
cd ocp4-upi-compute-powervs/support
mkdir -p /root/.openshift
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support-nfs-deploy.log ansible-playbook -e @vars/vars.yaml tasks/nfs_provisioner.yml --become || true
EOF
    ]
  }
}

resource "null_resource" "config_csi" {
  depends_on = [null_resource.config_login, null_resource.config]
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
oc annotate --kubeconfig /root/.kube/config ns openshift-cluster-csi-drivers \
  scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=amd64
EOF
    ]
  }
}

resource "null_resource" "adjust_mtu" {
  depends_on = [null_resource.config_csi]
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
echo "Skipping the MTU adjustment"
EOF
    ]
  }
}

resource "null_resource" "keep_dns_on_vpc" {
  count      = var.keep_dns ? 1 : 0
  depends_on = [null_resource.adjust_mtu]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: put the dns nodes on the VPC machines
  provisioner "remote-exec" {
    inline = [<<EOF
oc patch dns.operator/default -p '{ "spec" : {"nodePlacement": {"nodeSelector": {"kubernetes.io/arch" : "amd64"}}}}' --type merge
EOF
    ]
  }
}

resource "null_resource" "keep_imagepruner_on_vpc" {
  depends_on = [null_resource.keep_dns_on_vpc, null_resource.adjust_mtu]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: put the image pruner nodes on the VPC machines
  provisioner "remote-exec" {
    inline = [<<EOF
oc patch imagepruner/cluster -p '{ "spec" : {"nodeSelector": {"kubernetes.io/arch" : "amd64"}}}' --type merge -v=1
EOF
    ]
  }
}

# ovnkube between vpc/powervs requires routingViaHost for the LBs to work properly
# ref: https://community.ibm.com/community/user/powerdeveloper/blogs/mick-tarsel/2023/01/26/routingviahost-with-ovnkuberenetes
resource "null_resource" "set_routing_via_host" {
  depends_on = [null_resource.keep_imagepruner_on_vpc]
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
if [ "$(oc get Network.config cluster -o jsonpath='{.status.networkType}')" == "OVNKubernetes" ]
then
oc patch network.operator/cluster --type merge -p \
  '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"routingViaHost":true}}}}}'
fi
EOF
    ]
  }
}

resource "null_resource" "wait_on_mcp" {
  depends_on = [null_resource.set_routing_via_host, null_resource.adjust_mtu]
  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = var.bastion_public_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: added hardening to the MTU wait, we wait for the condition and then fail
  provisioner "remote-exec" {
    inline = [<<EOF
echo "-start - diagnostics for network and mtu-"
oc get network cluster -o json | jq -r '.status | .clusterNetworkMTU, .migration?'
oc get mcp
echo "-done - diagnostics for network and mtu-"
EOF
    ]
  }
}

# Dev Note: do this as the last step so we get a good worker ignition file downloaded.
resource "null_resource" "latest_ignition" {
  depends_on = [null_resource.wait_on_mcp]
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
echo 'Running ocp4-upi-compute-powervs playbook for ignition...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/ignition.yml --become
EOF
    ]
  }
}

# This resource is independent and is purely a warning for debugging purposes, and is marked as INFO intentionally.
resource "null_resource" "warn_worker_count" {
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
echo "INFO: number of workers is '${var.worker["count"]}'"
EOF
    ]
  }
}
