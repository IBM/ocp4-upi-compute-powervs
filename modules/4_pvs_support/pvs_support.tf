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

  # you must use the api-int url so the bastion routes over the correct interface.
  helpernode_vars = {
    client_tarball               = var.openshift_client_tarball
    openshift_machine_config_url = replace(replace(var.openshift_api_url, ":6443", ""), "://api.", "://api-int.")
    vpc_support_server_ip        = var.vpc_support_server_ip
    use_fixed_network            = var.use_fixed_network
    power_worker_count           = var.worker["count"]
    start_host                   = join(",", local.worker_hosts)
    gateway                      = cidrhost(var.powervs_machine_cidr, 1)
  }

  cidrs = {
    cidrs_ipv4 = var.cidrs
    gateway    = cidrhost(var.powervs_machine_cidr, 1)
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
    content     = replace(file(var.kubeconfig_file), "://api.", "://api-int.")
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
    content     = templatefile("${path.module}/templates/route-env3.tpl", local.cidrs)
    destination = "/etc/sysconfig/network-scripts/route-env3"
  }

  # Dev Note: need to move the route script to the right location
  provisioner "remote-exec" {
    inline = [<<EOF
act_dev_name=""
cidrs=("${local.cidr_str}")
for cidr in "$${cidrs[@]}"
do
  envs=($(ip r | grep "$cidr dev" | awk '{print $3}'))
  for env in "$${envs[@]}"
  do
    dev_name=$(sudo nmcli -t -f DEVICE connection show | grep $env)
    mv /etc/sysconfig/network-scripts/route-env3 /etc/sysconfig/network-scripts/route-$${dev_name}
    act_dev_name=$${dev_name}
  done
done

ifup $${act_dev_name}
echo 'Running ocp4-upi-compute-powervs playbook...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/main.yml --become
EOF
    ]
  }

  # Dev Note: setup the dhcp server for the workers
  provisioner "remote-exec" {
    inline = [<<EOF
echo 'Running ocp4-upi-compute-powervs playbook...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support-dhcp.log ansible-playbook -e @vars/vars.yaml tasks/dhcp.yml --become || true
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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc login \
  "${var.openshift_api_url}" -u "${var.openshift_user}" -p "${var.openshift_pass}" --insecure-skip-tls-verify=true
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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
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

  # The mtu.network.to was originally targetting 9000, and has been moved to 1350 based on the VPC/IBM Cloud configurations.
  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc patch Network.operator.openshift.io cluster --type=merge --patch \
  '{"spec": { "migration": { "mtu": { "network": { "from": 1400, "to": 1350 } , "machine": { "to" : 9100} } } } }'
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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc patch imagepruner/cluster -p '{ "spec" : {"nodeSelector": {"kubernetes.io/arch" : "amd64"}}}' --type merge -v=1
EOF
    ]
  }
}

#locals {
# Dev Note: considered `split("/", "${var.powervs_machine_cidr}")[1]` however, it needs to be smaller than the mask.
# ref: https://www.ibm.com/docs/en/zcxrhos/1.1.0?topic=parameters-network-configuration
#hostPrefix = 30
#}

# resource "null_resource" "alter_network_cluster_config" {
#   depends_on = [null_resource.keep_imagepruner_on_vpc]
#   connection {
#     type        = "ssh"
#     user        = var.rhel_username
#     host        = var.bastion_public_ip
#     private_key = file(var.private_key_file)
#     agent       = var.ssh_agent
#     timeout     = "${var.connection_timeout}m"
#   }

#   # Dev Note: adds the network so the OVN-KUBE settings are correct for a second network, and the LB doesn't end up in a loop.
#   # original logic was `jq '.spec.clusterNetwork += [{"cidr": "${var.powervs_machine_cidr}", "hostPrefix": ${local.hostPrefix}}]'`
#   provisioner "remote-exec" {
#     inline = [<<EOF
# export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
# dnf install -y jq
# echo "CIDRs are:"
# oc get Network.config.openshift.io cluster -ojson | jq -r '.spec.clusterNetwork[].cidr'
# [[ "$(oc get Network.config.openshift.io cluster -ojson | jq -r '.spec.clusterNetwork[].cidr')" != "192.168.0.0/16" ]] \
#   && oc get Network.config.openshift.io cluster -o json \
#   | jq '.spec.clusterNetwork += [{"cidr": "192.168.0.0/16", "hostPrefix": 24}]' \
#   | oc apply -f -
# EOF
#     ]
#   }
# }

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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"
oc patch network.operator/cluster --type merge -p \
  '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"gatewayConfig":{"routingViaHost":true}}}}}'
EOF
    ]
  }
}

resource "null_resource" "wait_on_mcp" {
  depends_on = [null_resource.set_routing_via_host]
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
export HTTPS_PROXY="http://${var.vpc_support_server_ip}:3128"

echo "-diagnostics-"
oc get network cluster -o yaml | grep -i mtu
oc get mcp

echo 'verifying worker mc'
start_counter=0
timeout_counter=10
mtu_output=`oc get mc 00-worker -o yaml | grep TARGET_MTU=9100`
# While loop waits for TARGET_MTU=9100 till timeout has not reached 
while [[ ( $mtu_output == "" ) && ( $start_counter -lt $timeout_counter ) ]];
do
  echo "waiting on worker"
  sleep 30
  mtu_output=`oc get mc 00-worker -o yaml | grep TARGET_MTU=9100`
  start_counter=`expr $start_counter + 1`
done
#oc wait mcp/worker --for condition=updated --timeout=5m || true

echo '-checking mtu-'
[[ "$( oc get network cluster -o yaml | grep 'to: 9100' | awk '{print $NF}')" == "9100" ]] || false
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
ifup env3
echo 'Running ocp4-upi-compute-powervs playbook for ignition...'
cd ocp4-upi-compute-powervs/support
ANSIBLE_LOG_PATH=/root/.openshift/ocp4-upi-compute-powervs-support.log ansible-playbook -e @vars/vars.yaml tasks/ignition.yml --become
EOF
    ]
  }
}
