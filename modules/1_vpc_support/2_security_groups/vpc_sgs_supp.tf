################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Loads the Security Groups so we can avoid duplication
data "ibm_is_security_groups" "supp_vm_sgs" {
  vpc_id = var.vpc
}

locals {
  sgs = [for x in data.ibm_is_security_groups.supp_vm_sgs.security_groups : x.id if x.name == "${var.vpc_name}-supp-sg"]
}

resource "ibm_is_security_group" "supp_vm_sg" {
  name           = "${var.vpc_name}-supp-sg"
  vpc            = var.vpc
  resource_group = var.resource_group
}

# allow all outgoing network traffic
resource "ibm_is_security_group_rule" "supp_vm_sg_outgoing_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "supp_vm_sg_ssh_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# allow all incoming network traffic on port 53
resource "ibm_is_security_group_rule" "supp_vm_sg_supp_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 53
    port_max = 53
  }
}

# Dev Note: the following are used by PowerVS and VPC VSIs.
# allow all incoming network traffic on port 2049
resource "ibm_is_security_group_rule" "nfs_1_vm_sg_ssh_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 2049
    port_max = 2049
  }
}

resource "ibm_is_security_group_rule" "nfs_1_vm_sg_ssh_all_vpc" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  tcp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_2_vm_sg_ssh_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 111
    port_max = 111
  }
}

resource "ibm_is_security_group_rule" "nfs_2_vm_sg_ssh_all_vpc" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  tcp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic on port 2049
resource "ibm_is_security_group_rule" "nfs_3_vm_sg_ssh_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr

  udp {
    port_min = 2049
    port_max = 2049
  }
}

resource "ibm_is_security_group_rule" "nfs_3_vm_sg_ssh_all_vpc" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  udp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_4_vm_sg_ssh_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 111
    port_max = 111
  }
}

resource "ibm_is_security_group_rule" "nfs_4_vm_sg_ssh_all_vpc" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  udp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic for ping
resource "ibm_is_security_group_rule" "supp_vm_sg_ping_all" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  icmp {
    type = 8
    code = 1
  }
}

resource "ibm_is_security_group_rule" "supp_vm_sg_ping_all_vpc" {
  group     = ibm_is_security_group.supp_vm_sg.id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  icmp {
    type = 8
    code = 1
  }
}

locals {
  sg_id = local.sgs == [] ? ibm_is_security_group.supp_vm_sg.id : local.sgs[0]
}
