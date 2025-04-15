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

  # Routing issues - we removed api-int and left the logic inplace so we can switch back
  openshift_machine_config_url = replace(replace(var.openshift_api_url, ":6443", ""), "://api.", "://api.")
  oauth_hostname               = replace(replace(local.openshift_machine_config_url, "://api.", "oauth-openshift.apps."), "https", "")
  oauth_ip                     = var.lbs_ips

  # you must use the api-int url so the bastion routes over the correct interface.
  helpernode_vars = {
    client_tarball               = var.openshift_client_tarball
    openshift_machine_config_url = local.openshift_machine_config_url
    vpc_support_server_ip        = var.vpc_support_server_ip
    power_worker_count           = var.worker["count"]
    start_host                   = join(",", local.worker_hosts)
    gateway                      = cidrhost(var.powervs_machine_cidr, 1)
    nfs_server                   = var.nfs_server
    nfs_path                     = var.nfs_path
    cicd                         = var.cicd
    target_mtu                   = var.cluster_network_mtu
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
    content     = templatefile("${path.module}/templates/inventory.tpl", local.helpernode_inventory)
    destination = "ocp4-upi-compute-powervs/support/inventory"
  }

  provisioner "file" {
    content     = templatefile("${path.module}/templates/vars.yaml.tpl", local.helpernode_vars)
    destination = "ocp4-upi-compute-powervs/support/vars/vars.yaml"
  }

  # Copies the custom route for env3
  provisioner "file" {
    content     = templatefile("${path.module}/templates/route-env.sh.tpl", local.cidrs)
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
echo "Update hosts file with OAuth Details"
if !(grep -q "${local.oauth_ip}" /etc/hosts); then
        echo "${local.oauth_ip} ${local.oauth_hostname} oauth-openshift" >> /etc/hosts
fi
oc login \
  "${local.openshift_machine_config_url}" -u "${var.openshift_user}" -p "${var.openshift_pass}" --insecure-skip-tls-verify=true
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

  # The mtu.network.to was originally targetting 9000, and has been moved to ${var.cluster_network_mtu} (Default 1350) based on the VPC/IBM Cloud configurations. User can override it by setting desired value in var.tfvars file
  # we previously supported OpenShiftSDN since it's deprecation we have removed it from automation.
  provisioner "remote-exec" {
    inline = [<<EOF
EXISTING_MTU=$(oc get network cluster -o json | jq -r .status.clusterNetworkMTU)

if [ $EXISTING_MTU != ${var.cluster_network_mtu} ]
then
  echo "Setting clusterNetworkMTU to ${var.cluster_network_mtu}"
  echo "Patch command output is:"
  oc patch Network.operator.openshift.io cluster --type=merge --patch \
    '{"spec": { "migration": { "mtu": { "network": { "from": '$EXISTING_MTU', "to": ${var.cluster_network_mtu} } , "machine": { "to" : ${var.private_network_mtu}} } } } }'
else
  echo "clusterNetworkMTU is already set to ${var.cluster_network_mtu}"
fi
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
echo "-diagnostics-"
oc get network cluster -o yaml | grep -i mtu
oc get mcp

echo 'verifying worker mc'
start_counter=0
timeout_counter=10
mtu_output=`oc get mc 00-worker -o yaml | grep TARGET_MTU=${var.private_network_mtu}`
echo "(DEBUG) MTU FOUND?: $${mtu_output}"
# While loop waits for TARGET_MTU=${var.private_network_mtu} till timeout has not reached 
while [[ "$(oc get network cluster -o yaml | grep 'to: ${var.private_network_mtu}' | awk '{print $NF}')" != "${var.private_network_mtu}" ]]
do
  echo "waiting on worker"
  sleep 30
done

# Check clusterNetworkMTU
cl_network_mtu=$(oc get network cluster -o json | jq -r .status.clusterNetworkMTU)
echo "(DEBUG) clusterNetworkMTU FOUND?: $${cl_network_mtu}"

# While loop waits for clusterNetworkMTU=var.cluster_network_mtu (Default 1350) till timeout has not reached
while [[ "$(oc get network cluster -o json | jq -r .status.clusterNetworkMTU)" != "${var.cluster_network_mtu}" ]]
do
  echo "waiting for clusterNetworkMTU to be ${var.cluster_network_mtu}"
  sleep 30

  start_counter=$(expr $start_counter + 1)

  # Break the loop if timeout occurs
  if [ $start_counter -gt $timeout_counter ]
  then
    echo "exceeding the loop timeout: $${start_counter}"
    break
  fi
done

RENDERED_CONFIG=$(oc get mcp/worker -o json | jq -r '.spec.configuration.name')
CHECK_CONFIG=$(oc get mc $${RENDERED_CONFIG} -ojson 2>&1 | grep TARGET_MTU=${var.private_network_mtu})
while [ -z "$${CHECK_CONFIG}" ]
do
  echo "waiting on worker"
  sleep 30
  RENDERED_CONFIG=$(oc get mcp/worker -o json | jq -r '.spec.configuration.name')
  CHECK_CONFIG=$(oc get mc $${RENDERED_CONFIG} -ojson 2>&1 | grep TARGET_MTU=${var.private_network_mtu})
done

echo '-checking mtu-'
oc get network cluster -o yaml | grep 'to: ${var.private_network_mtu}' | awk '{print $NF}'
[[ "$(oc get network cluster -o yaml | grep 'to: ${var.private_network_mtu}' | awk '{print $NF}')" == "${var.private_network_mtu}" ]] || false
echo "success on wait on mtu change"
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
nmcli device up env3
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
