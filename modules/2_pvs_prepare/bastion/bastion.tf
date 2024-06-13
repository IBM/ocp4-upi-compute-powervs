################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

resource "ibm_pi_instance" "bastion" {
  count = 1

  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_memory            = var.bastion["memory"]
  pi_processors        = var.bastion["processors"]
  pi_instance_name     = "${var.name_prefix}-bastion-${count.index}"
  pi_proc_type         = var.processor_type
  pi_image_id          = var.bastion_image_id
  pi_key_pair_name     = var.key_name
  pi_sys_type          = var.system_type
  pi_health_status     = var.bastion_health_status
  # Dev Note: PER Network enablement, we chose to use tier1 only.
  pi_storage_type = "tier1"
  #pi_storage_pool = var.bastion_storage_pool

  pi_network {
    network_id = var.bastion_public_network_id
  }

  # Dev Note: this dhcp network ip does not always register with the cloud api
  pi_network {
    network_id = var.powervs_network_id
  }
}

# Dev Note: injects a delay before a hard-reboot
resource "time_sleep" "wait_bastion" {
  depends_on      = [ibm_pi_instance.bastion]
  create_duration = "120s"
}

resource "ibm_pi_instance_action" "restart_bastion" {
  depends_on           = [time_sleep.wait_bastion]
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_instance_id       = ibm_pi_instance.bastion[0].instance_id
  pi_action            = "hard-reboot"
  pi_health_status     = "WARNING"
}

data "ibm_pi_instance_ip" "bastion_public_ip" {
  count      = 1
  depends_on = [ibm_pi_instance.bastion]

  pi_instance_name     = ibm_pi_instance.bastion[count.index].pi_instance_name
  pi_network_name      = var.bastion_public_network_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}

locals {
  ext_ip = data.ibm_pi_instance_ip.bastion_public_ip[0].external_ip
}

resource "null_resource" "bastion_nop" {
  count      = 1
  depends_on = [data.ibm_pi_instance_ip.bastion_public_ip, time_sleep.wait_bastion, ibm_pi_instance_action.restart_bastion]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = local.ext_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }
  provisioner "remote-exec" {
    inline = [
      "whoami"
    ]
  }
}

#### Configure the Bastion
resource "null_resource" "bastion_init" {
  count = 1

  depends_on = [null_resource.bastion_nop]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = local.ext_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  provisioner "file" {
    content     = file(var.private_key_file)
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
EOF
    ]
  }
}

resource "null_resource" "bastion_register" {
  count      = (var.rhel_subscription_username == "" || var.rhel_subscription_username == "<subscription-id>") && var.rhel_subscription_org == "" ? 0 : 1
  depends_on = [null_resource.bastion_init]
  triggers = {
    external_ip        = local.ext_ip
    rhel_username      = var.rhel_username
    private_key        = sensitive(file(var.private_key_file))
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
  count      = 1
  depends_on = [null_resource.bastion_init, null_resource.bastion_register]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = local.ext_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # The timeout is a guard against flakes in the dns lookup for mirrolist.centos.org and dl.fedoraproject.org
  provisioner "remote-exec" {
    inline = [<<EOF
# Additional repo for installing ansible package
if ( [[ -z "${var.rhel_subscription_username}" ]] || [[ "${var.rhel_subscription_username}" == "<subscription-id>" ]] ) && [[ -z "${var.rhel_subscription_org}" ]]
then
  timeout 300 bash -c -- 'until ping -c 1 mirrorlist.centos.org; do sleep 30; printf ".";done'
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
    timeout 300 bash -c -- 'until ping -c 1 dl.fedoraproject.org; do sleep 30; printf ".";done'
    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
  fi
fi
EOF
    ]
  }
}

resource "null_resource" "manage_packages" {
  count      = 1
  depends_on = [null_resource.bastion_init, null_resource.bastion_register, null_resource.enable_repos]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = local.ext_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # Dev Note: transient connection errors to centos may occur, and the || provides resilient reruns of the command
  provisioner "remote-exec" {
    inline = [
      <<EOF
sudo yum install -y wget jq git net-tools vim python3 tar \
  || sleep 60s \
  && sudo yum install -y wget jq git net-tools vim python3 tar
EOF
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

  provisioner "remote-exec" {
    inline = [
      "sudo yum remove cloud-init --noautoremove -y",
    ]
  }

  # Dev Note: rsct status is reported back to the PowerVS.
  # see https://github.com/canonical/cloud-init/blob/349ca1e10e70d305d018102d7ee08e7826220e43/cloudinit/config/cc_reset_rmc.py#L130
  # /usr/sbin/rsct/bin/rmcctrl -z
  # /usr/sbin/rsct/install/bin/recfgct
  provisioner "remote-exec" {
    inline = [<<EOF
lssrc -a
#rmcdomainstatus -s ctrmc -a IP > /var/log/rsct.status && [ -s /var/log/rsct.status ]
systemctl enable srcmstr && systemctl enable ctrmc
systemctl start srcmstr && systemctl start ctrmc
echo "RSCT NODE_ID = $(head -n 1 /etc/ct_node_id)"
sleep 60s
echo "proceeding to next step..."
EOF
    ]
  }
}

locals {
  cidr   = split("/", var.powervs_network_cidr)[0]
  gw     = cidrhost(var.powervs_network_cidr, 1)
  int_ip = cidrhost(var.powervs_network_cidr, 3)
}

resource "null_resource" "bastion_fix_up_networks" {
  count      = 1
  depends_on = [null_resource.manage_packages]

  connection {
    type        = "ssh"
    user        = var.rhel_username
    host        = local.ext_ip
    private_key = file(var.private_key_file)
    agent       = var.ssh_agent
    timeout     = "${var.connection_timeout}m"
  }

  # dev-note: mtu is set to 9000 on the external interface/pubnet
  # also turning off tx-checksum
  # ip link set env2 mtu 9000
  provisioner "remote-exec" {
    inline = [<<EOF
ip link set env2 mtu 9000
/sbin/ethtool --offload env2 tx-checksumming off
EOF
    ]
  }

  # Identifies the networks, and picks the iface that is on the private networkfor_each

  provisioner "remote-exec" {
    inline = [<<EOF
      DEV_NAME=$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo ! -name '*bond*' -printf "%P " -execdir cat {}/address \; | \
          grep -v lo | grep -v env2 | awk '{print $1}' | head -n 1)

      nmcli dev mod $${DEV_NAME} ipv4.addresses ${local.int_ip} \
        ipv4.gateway ${local.gw} \
        ipv4.dns "${var.vpc_support_server_ip}" \
        ipv4.method manual \
        connection.autoconnect yes \
        802-3-ethernet.mtu 9000

        nmcli dev up $${DEV_NAME}
  EOF
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
    inline = [<<EOF
# turn off rx and set mtu to var.private_network_mtu for all interfaces to improve network performance
cidrs=("${var.bastion_public_network_cidr}" "${local.cidr}")
for cidr in "$${cidrs[@]}"
do
  envs=($(ip r | grep "$cidr dev" | awk '{print $3}'))
  for env in "$${envs[@]}"
  do
    dev_name=$(sudo nmcli -t -f DEVICE connection show | grep $env)
    sudo nmcli device modify "$dev_name" ethtool.feature-rx off
    sudo nmcli device modify "$dev_name" ethernet.mtu ${var.private_network_mtu}
    sudo nmcli device up "$dev_name"
  done
done
EOF
    ]
  }
}