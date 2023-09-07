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
  count          = local.sgs == [] ? 1 : 0
  name           = "${var.vpc_name}-supp-sg"
  vpc            = var.vpc
  resource_group = var.resource_group
}

# allow all outgoing network traffic
resource "ibm_is_security_group_rule" "supp_vm_sg_outgoing_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "supp_vm_sg_ssh_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

# Dev Note: The rules apply to powervs instances to connect to the api-int
# allow all incoming network traffic on port 3128
resource "ibm_is_security_group_rule" "squid_vm_sg_ssh_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr

  tcp {
    port_min = 3128
    port_max = 3128
  }
}

# allow all incoming network traffic on port 53
resource "ibm_is_security_group_rule" "supp_vm_sg_supp_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
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
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 2049
    port_max = 2049
  }
}

resource "ibm_is_security_group_rule" "nfs_1_vm_sg_ssh_all_vpc" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  tcp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_2_vm_sg_ssh_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 111
    port_max = 111
  }
}

resource "ibm_is_security_group_rule" "nfs_2_vm_sg_ssh_all_vpc" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  tcp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic on port 2049
resource "ibm_is_security_group_rule" "nfs_3_vm_sg_ssh_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr

  udp {
    port_min = 2049
    port_max = 2049
  }
}

resource "ibm_is_security_group_rule" "nfs_3_vm_sg_ssh_all_vpc" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  udp {
    port_min = 2049
    port_max = 2049
  }
}

# allow all incoming network traffic on port 111
resource "ibm_is_security_group_rule" "nfs_4_vm_sg_ssh_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 111
    port_max = 111
  }
}

resource "ibm_is_security_group_rule" "nfs_4_vm_sg_ssh_all_vpc" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  udp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic for ping
resource "ibm_is_security_group_rule" "supp_vm_sg_ping_all" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  icmp {
    type = 8
    code = 1
  }
}

resource "ibm_is_security_group_rule" "supp_vm_sg_ping_all_vpc" {
  count     = local.sgs == [] ? 1 : 0
  group     = ibm_is_security_group.supp_vm_sg[0].id
  direction = "inbound"
  remote    = local.openshift_net_sg[0].id
  icmp {
    type = 8
    code = 1
  }
}

locals {
  sg_id = local.sgs == [] ? ibm_is_security_group.supp_vm_sg[0].id : local.sgs[0]
}