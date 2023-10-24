################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Dev Note: nop is a debug step
resource "null_resource" "nop" {
  triggers = {
    bastion_private_ip_mac = var.ignition_mac
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo "Waiting on DHCP Lease to be registered"
sleep 15
echo "Done waiting on DHCP Lease to be registered"
echo ""
echo "IP Information"
ip a

echo "Looking for mac: ${var.ignition_mac}"
EOF
    ]
  }
}

### Grab the Bastion Data
data "ibm_pi_dhcp" "refresh_dhcp_server" {
  count                = var.use_fixed_network ? 0 : 1
  depends_on           = [null_resource.nop]
  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_dhcp_id           = var.powervs_dhcp_service
}

data "ibm_pi_instance" "bastion_instance" {
  depends_on           = [data.ibm_pi_dhcp.refresh_dhcp_server]
  pi_instance_name     = var.powervs_bastion_name
  pi_cloud_instance_id = var.powervs_service_instance_id
}

locals {
  # Dev Note: Leases should return the IP, however, they are returning empty in some data centers and existing workspaces.
  # the conditionals are: 
  # 1. if fixed network, pull off the bastion_instance
  # 2. if other network, pull off lease from dhcp server
  # 3. if not found, use the pub-net ip
  bastion_private_ip = var.use_fixed_network ? [] : [for lease in data.ibm_pi_dhcp.refresh_dhcp_server[0].leases : lease if lease.instance_mac == data.ibm_pi_instance.bastion_instance.networks[0].macaddress]
}

# Dev Note: the hypervisor does not report the internal interfaces ip correctly
# This resource works around that problem through a temporary setup of an http 
resource "null_resource" "secondary_retrieval_ignition_ip" {
  count      = var.cicd ? 1 : 0
  depends_on = [null_resource.nop]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  provisioner "remote-exec" {
    inline = [<<EOF
echo "Listen 443" > /etc/httpd/conf.d/extra.conf
systemctl restart httpd
for IFACE in $(nmcli device show 2>&1| grep GENERAL.DEVICE | grep -v env2 | grep -v lo | awk '{print $NF}')
do
    IP_ADDR="$(nmcli device show $${IFACE} 2>&1 | grep IP4.ADDRESS | sed 's|/24||g' | awk '{print $NF}')"
    if [ -n "$${IP_ADDR}" ]
    then 
        echo "Interface: $${IFACE} $${IP_ADDR}"
        echo "$${IP_ADDR}" > /var/www/html/ip
        chmod 777 /var/www/html/ip
    fi
done
EOF
    ]
  }
}

data "http" "bastion_ip_retrieval" {
  count      = var.cicd ? 1 : 0
  depends_on = [null_resource.secondary_retrieval_ignition_ip]
  url        = "http://${var.bastion_public_ip}:443/ip"
}

# Dev Note: at the end the https port shouldn't be active/listening
resource "null_resource" "secondary_retrieval_shutdown" {
  count      = var.cicd ? 1 : 0
  depends_on = [null_resource.nop, data.http.bastion_ip_retrieval, null_resource.secondary_retrieval_ignition_ip]

  triggers = {
    private_key = file(var.private_key_file)
    host        = var.bastion_public_ip
    agent       = var.ssh_agent
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = self.triggers.private_key
    host        = self.triggers.host
    agent       = self.triggers.agent
  }

  provisioner "remote-exec" {
    inline = [<<EOF
rm -f /etc/httpd/conf.d/extra.conf
systemctl restart httpd
EOF
    ]
  }

  # Dev Note: When destroy, we need to recreate
  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [<<EOF
echo "Listen 443" > /etc/httpd/conf.d/extra.conf
systemctl restart httpd
EOF
    ]
  }
}

locals {
  ignition_ip = var.use_fixed_network ? data.ibm_pi_instance.bastion_instance.networks[0].ip : length(var.ignition_ip) > 0 ? var.ignition_ip[0].instance_ip : length(local.bastion_private_ip) > 0 ? local.bastion_private_ip[0].instance_ip : chomp(data.http.bastion_ip_retrieval[0].response_body)
}

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  depends_on = [data.ibm_pi_dhcp.refresh_dhcp_server, null_resource.nop, null_resource.secondary_retrieval_shutdown]

  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_instance_name     = "${var.name_prefix}-worker-${count.index}"

  pi_sys_type   = var.system_type
  pi_proc_type  = var.processor_type
  pi_memory     = var.worker["memory"]
  pi_processors = var.worker["processors"]
  pi_image_id   = var.rhcos_image_id

  pi_network {
    network_id = var.powervs_dhcp_network_id
  }

  pi_key_pair_name = var.key_name
  pi_health_status = "WARNING"

  ### DEV NOTE to fully support FIXED NETWORK
  # need a different worker.ign with static ip setting a kernel arg using ignition following this pattern:
  # ip={{ item.ipaddr }}::{{ static_ip.gateway }}:{{ static_ip.netmask }}:{{ infraID.stdout }}-{{ item.name }}:ens192:off:{{ coredns_vm.ipaddr }}
  pi_user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/5_worker/templates/worker.ign",
      {
        ignition_ip : "${local.ignition_ip}",
        name : base64encode("${var.name_prefix}-worker-${count.index}"),
  }))
}
