################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

provider "ibm" {
  alias            = "vpc"
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.vpc_region
}

data "ibm_is_vpc" "ibm_is_vpc" {
  provider = ibm.vpc
  name     = var.vpc_name
}

locals {
  bastion_count = lookup(var.bastion, "count", 1)
}

data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = var.service_instance_id
}

locals {
  catalog_bastion_image = [for x in data.ibm_pi_catalog_images.catalog_images.images : x if x.name == var.rhel_image_name]
  bastion_image_id      = length(local.catalog_bastion_image) == 0 ? data.ibm_pi_image.bastion[0].id : local.catalog_bastion_image[0].image_id
  bastion_storage_pool  = length(local.catalog_bastion_image) == 0 ? data.ibm_pi_image.bastion[0].storage_pool : local.catalog_bastion_image[0].storage_pool
}

data "ibm_pi_image" "bastion" {
  count                = length(local.catalog_bastion_image) == 0 ? 1 : 0
  pi_image_name        = var.rhel_image_name
  pi_cloud_instance_id = var.service_instance_id
}

data "ibm_pi_network" "network" {
  pi_network_name      = var.powervs_network_name
  pi_cloud_instance_id = var.service_instance_id
}

resource "ibm_pi_network" "public_network" {
  pi_network_name      = "${var.name_prefix}-pub-net"
  pi_cloud_instance_id = var.service_instance_id
  pi_network_type      = "pub-vlan"
  pi_dns               = var.network_dns
}

resource "ibm_pi_key" "key" {
  pi_cloud_instance_id = var.service_instance_id
  pi_key_name          = "${var.name_prefix}-keypair"
  pi_ssh_key           = var.public_key
}

resource "ibm_pi_instance" "bastion" {
  count = local.bastion_count

  pi_memory            = var.bastion["memory"]
  pi_processors        = var.bastion["processors"]
  pi_instance_name     = "${var.name_prefix}-bastion-${count.index}"
  pi_proc_type         = var.processor_type
  pi_image_id          = local.bastion_image_id
  pi_key_pair_name     = ibm_pi_key.key.name
  pi_sys_type          = var.system_type
  pi_cloud_instance_id = var.service_instance_id
  pi_health_status     = var.bastion_health_status
  pi_storage_pool      = local.bastion_storage_pool

  pi_network {
    network_id = ibm_pi_network.public_network.network_id
  }
  pi_network {
    network_id = data.ibm_pi_network.network.id
  }
}

data "ibm_pi_instance_ip" "bastion_ip" {
  count      = local.bastion_count
  depends_on = [ibm_pi_instance.bastion]

  pi_instance_name     = ibm_pi_instance.bastion[count.index].pi_instance_name
  pi_network_name      = data.ibm_pi_network.network.pi_network_name
  pi_cloud_instance_id = var.service_instance_id
}

data "ibm_pi_instance_ip" "bastion_public_ip" {
  count      = local.bastion_count
  depends_on = [ibm_pi_instance.bastion]

  pi_instance_name     = ibm_pi_instance.bastion[count.index].pi_instance_name
  pi_network_name      = ibm_pi_network.public_network.pi_network_name
  pi_cloud_instance_id = var.service_instance_id
}

resource "null_resource" "bastion_init" {
  count = local.bastion_count

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [
      "whoami"
    ]
  }
  provisioner "file" {
    content     = var.private_key
    destination = ".ssh/id_rsa"
  }
  provisioner "file" {
    content     = var.public_key
    destination = ".ssh/id_rsa.pub"
  }
  provisioner "remote-exec" {
    inline = [<<EOF

sudo chmod 600 .ssh/id_rsa*
sudo sed -i.bak -e 's/^ - set_hostname/# - set_hostname/' -e 's/^ - update_hostname/# - update_hostname/' /etc/cloud/cloud.cfg
sudo hostnamectl set-hostname --static ${lower(var.name_prefix)}-bastion-${count.index}.${var.cluster_domain}
echo 'HOSTNAME=${lower(var.name_prefix)}-bastion-${count.index}.${var.cluster_domain}' | sudo tee -a /etc/sysconfig/network > /dev/null
sudo hostname -F /etc/hostname
echo 'vm.max_map_count = 262144' | sudo tee --append /etc/sysctl.conf > /dev/null

# Set SMT to user specified value; Should not fail for invalid values.
sudo ppc64_cpu --smt=${var.rhel_smt} | true

# turn off rx and set mtu to var.private_network_mtu for all interfaces to improve network performance
cidrs=("${ibm_pi_network.public_network.pi_cidr}" "${data.ibm_pi_network.network.cidr}")
for cidr in "$${cidrs[@]}"; do
  envs=($(ip r | grep "$cidr dev" | awk '{print $3}'))
  for env in "$${envs[@]}"; do
    con_name=$(sudo nmcli -t -f NAME connection show | grep $env)
    sudo nmcli connection modify "$con_name" ethtool.feature-rx off
    sudo nmcli connection modify "$con_name" ethernet.mtu ${var.private_network_mtu}
    sudo nmcli connection up "$con_name"
  done
done
EOF
    ]
  }
}

resource "null_resource" "bastion_register" {
  count      = (var.rhel_subscription_username == "" || var.rhel_subscription_username == "<subscription-id>") && var.rhel_subscription_org == "" ? 0 : local.bastion_count
  depends_on = [null_resource.bastion_init]
  triggers = {
    external_ip        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    rhel_username      = var.rhel_username
    private_key        = var.private_key
    ssh_agent          = var.ssh_agent
    connection_timeout = var.connection_timeout
  }

  connection {
    type        = "ssh"
    user        = self.triggers.rhel_username
    host        = self.triggers.external_ip
    private_key = self.triggers.private_key
    agent       = self.triggers.ssh_agent
    timeout     = "${self.triggers.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
if which subscription-manager
then
  # Give some more time to subscription-manager
  sudo subscription-manager config --server.server_timeout=600
  sudo subscription-manager clean
  if [[ '${var.rhel_subscription_username}' != '' && '${var.rhel_subscription_username}' != '<subscription-id>' ]]; then 
      sudo subscription-manager register --username='${var.rhel_subscription_username}' --password='${var.rhel_subscription_password}' --force
  else
      sudo subscription-manager register --org='${var.rhel_subscription_org}' --activationkey='${var.rhel_subscription_activationkey}' --force
  fi
  sudo subscription-manager refresh
  sudo subscription-manager attach --auto
fi
EOF
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp/terraform_*"
    ]
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = self.triggers.rhel_username
      host        = self.triggers.external_ip
      private_key = self.triggers.private_key
      agent       = self.triggers.ssh_agent
      timeout     = "2m"
    }
    when       = destroy
    on_failure = continue
    inline = [<<EOF
if which subscription-manager
then
  sudo subscription-manager unregister
  sudo subscription-manager remove --all
fi
EOF
    ]
  }
}

resource "null_resource" "enable_repos" {
  count      = local.bastion_count
  depends_on = [null_resource.bastion_init, null_resource.bastion_register]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
# Additional repo for installing ansible package
if ( [[ -z "${var.rhel_subscription_username}" ]] || [[ "${var.rhel_subscription_username}" == "<subscription-id>" ]] ) && [[ -z "${var.rhel_subscription_org}" ]]
then
  sudo yum install -y epel-release
else
  os_ver=$(cat /etc/os-release | egrep "^VERSION_ID=" | awk -F'"' '{print $2}')
  if [[ $os_ver != "9"* ]]
  then
    if which subscription-manager
    then
      sudo subscription-manager repos --enable ${var.ansible_repo_name}
    fi
  else
    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  fi
fi
EOF
    ]
  }
}

resource "null_resource" "bastion_packages" {
  count      = local.bastion_count
  depends_on = [null_resource.bastion_init, null_resource.bastion_register, null_resource.enable_repos]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y wget jq git net-tools vim python3 tar"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl unmask NetworkManager",
      "sudo systemctl start NetworkManager",
      "for i in $(nmcli device | grep unmanaged | awk '{print $1}'); do echo NM_CONTROLLED=yes | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-$i; done",
      "sudo systemctl restart NetworkManager",
      "sudo systemctl enable NetworkManager"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y ansible",
      "ansible-galaxy collection install community.crypto",
      "ansible-galaxy collection install ansible.posix",
      "ansible-galaxy collection install kubernetes.core"
    ]
  }
}

resource "null_resource" "cloud_init_remove" {
  count      = local.bastion_count
  depends_on = [null_resource.bastion_packages]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo yum remove cloud-init --noautoremove -y",
    ]
  }
}

resource "ibm_pi_network_port_attach" "bastion_internal_vip" {
  count      = local.bastion_count > 1 ? 1 : 0
  depends_on = [ibm_pi_instance.bastion]

  pi_cloud_instance_id        = var.service_instance_id
  pi_instance_id              = ibm_pi_instance.bastion[count.index].instance_id
  pi_network_name             = data.ibm_pi_network.network.pi_network_name
  pi_network_port_description = "Internal VIP"
}

resource "ibm_pi_network_port_attach" "bastion_external_vip" {
  count      = local.bastion_count > 1 ? 1 : 0
  depends_on = [ibm_pi_instance.bastion]

  pi_cloud_instance_id        = var.service_instance_id
  pi_instance_id              = ibm_pi_instance.bastion[count.index].instance_id
  pi_network_name             = ibm_pi_network.public_network.pi_network_name
  pi_network_port_description = "External VIP"
}

# Depends on the url/user/pass to annotate the csi namespace
# causing the scheduler to place the workload only on amd64 nodes
resource "null_resource" "exclude_vpc_csi" {
  count      = local.bastion_count
  depends_on = [null_resource.cloud_init_remove]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = data.ibm_pi_instance_ip.bastion_public_ip[count.index].external_ip
    private_key = var.private_key
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "remote-exec" {
    inline = [<<EOF
export HTTPS_PROXY="http://10.248.0.6:3128"
oc login \
  "${var.openshift_api_url}" -u "${var.openshift_user}" -p "${var.openshift_pass}" --insecure-skip-tls-verify=true
oc annotate ns openshift-cluster-csi-drivers \
    scheduler.alpha.kubernetes.io/node-selector=kubernetes.io/arch=amd64
EOF
    ]
  }
}