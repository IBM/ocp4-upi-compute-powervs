################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Based on reference https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

locals {
  public_key_file = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : "${path.cwd}/${var.public_key_file}"
  public_key      = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

resource "ibm_is_ssh_key" "dns_ssh_key" {
  count      = 1
  name       = "${var.vpc_name}-dns-ssh-key"
  public_key = local.public_key

  resource_group = data.ibm_is_vpc.ex_vpc.resource_group
}

data "ibm_is_vpc" "ex_vpc" {
  name = var.vpc_name
}

resource "ibm_is_security_group" "dns_vm_sg" {
  count = 1
  name  = "${var.vpc_name}-dns-sg"
  vpc   = data.ibm_is_vpc.ex_vpc.id

  resource_group = data.ibm_is_vpc.ex_vpc.resource_group
}

# allow all outgoing network traffic
resource "ibm_is_security_group_rule" "dns_vm_sg_outgoing_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "dns_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

# allow all incoming network traffic on port 3128
resource "ibm_is_security_group_rule" "squid_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 3128
    port_max = 3128
  }
}

# allow all incoming network traffic on port 2049
resource "ibm_is_security_group_rule" "nfs_1_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_2_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic on port 2049
resource "ibm_is_security_group_rule" "nfs_3_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_4_vm_sg_ssh_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic on port 53
resource "ibm_is_security_group_rule" "dns_vm_sg_dns_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

# allow all incoming network traffic for ping
resource "ibm_is_security_group_rule" "dns_vm_sg_ping_all" {
  count     = 1
  group     = ibm_is_security_group.dns_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
    code = 1
  }
}

data "ibm_is_image" "dns_vm_image" {
  count = 1
  name  = var.dns_vm_image_name
}

resource "ibm_is_instance" "dns_vm_vsi" {
  count = 1

  depends_on = [ibm_is_ssh_key.dns_ssh_key]

  name    = "${var.vpc_name}-dns-vsi"
  vpc     = data.ibm_is_vpc.ex_vpc.id
  zone    = data.ibm_is_vpc.ex_vpc.subnets[0].zone
  keys    = [ibm_is_ssh_key.dns_ssh_key[0].id]
  image   = data.ibm_is_image.dns_vm_image[0].id
  profile = "cx2d-8x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Originally used cx2-2x4, however 8x16 includes 300G storage.

  resource_group = data.ibm_is_vpc.ex_vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.ex_vpc.subnets[0].id
    security_groups = [ibm_is_security_group.dns_vm_sg[0].id]
  }

  user_data = templatefile("${path.cwd}/modules/0_vpc_support/templates/cloud-init.yaml.tpl", {
    domain : split(separator, string),
  })
}