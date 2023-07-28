################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Updates the IPI IBMCLOUD OCP4 install with SG updates necessary to bolt on PowerVS workers.

# Loads the VPC Security Groups so we can find the existing ids
data "ibm_is_security_groups" "sgs" {
  vpc_id = data.ibm_is_vpc.vpc.id
}

locals {
  control_plane_sg = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "sg-control-plane")]
  cluster_wide_sg  = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "sg-cluster-wide")]
  cp_internal_sg   = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "sg-cp-internal")]
  kube_api_lb_sg   = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "sg-kube-api-lb")]
  openshift_net_sg = [for x in data.ibm_is_security_groups.sgs.security_groups : x if endswith(x.name, "sg-openshift-net")]
}

# sg-control-plane
# TCP 22623 192.168.200.0/24 (MachineConfig)
# TCP 6443 192.168.200.0/24 (API)

resource "ibm_is_security_group_rule" "control_plane_sg_mc" {
  count     = local.control_plane_sg[0].rules
  group     = local.control_plane_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 22623
    port_max = 22623
  }
}

resource "ibm_is_security_group_rule" "control_plane_sg_api" {
  group     = local.control_plane_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 6443
    port_max = 6443
  }
}

# sg-cluster-wide
#UDP 	6081 	192.168.200.0/24
#ICMP 	Any 	192.168.200.0/24
#UDP 	4789 	192.168.200.0/24
#TCP 	22 	192.168.200.0/24

resource "ibm_is_security_group_rule" "cluster_wide_sg_6081" {
  group     = local.cluster_wide_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 6081
    port_max = 6081
  }
}

resource "ibm_is_security_group_rule" "cluster_wide_sg_any" {
  group     = local.cluster_wide_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  icmp {
  }
}

resource "ibm_is_security_group_rule" "cluster_wide_sg_4789" {
  group     = local.cluster_wide_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 4789
    port_max = 4789
  }
}

resource "ibm_is_security_group_rule" "cluster_wide_sg_ssh" {
  group     = local.cluster_wide_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

# sg-cp-internal
#TCP 	2379-2380 	192.168.200.0/24
#TCP 	10257-10259 	192.168.200.0/24

resource "ibm_is_security_group_rule" "cp_internal_sg_r1" {
  group     = local.cp_internal_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 2379
    port_max = 2380
  }
}

resource "ibm_is_security_group_rule" "cp_internal_sg_r2" {
  group     = local.cp_internal_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 10257
    port_max = 10259
  }
}

# Adds the VPC Support machine to the target
resource "ibm_is_security_group_target" "cp_internal_supp_vm" {
  security_group = local.cp_internal_sg[0].id
  target         = ibm_is_instance.supp_vm_vsi[0].id
}

# sg-kube-api-lb
# TCP (IN) 	22623 	192.168.200.0/24
# TCP (Out) 	22623 	192.168.200.0/24
# TCP (Out) 	6443 	192.168.200.0/24
# TCP (Out) 	80 	192.168.200.0/24
# TCP (Out) 	443 	192.168.200.0/24

resource "ibm_is_security_group_rule" "kube_api_lb_sg_mc" {
  group     = local.kube_api_lb_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 22623
    port_max = 22623
  }
}

resource "ibm_is_security_group_rule" "kube_api_lb_sg_mc_out" {
  group     = local.kube_api_lb_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 22623
    port_max = 22623
  }
}

resource "ibm_is_security_group_rule" "kube_api_lb_sg_api_out" {
  group     = local.kube_api_lb_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 6443
    port_max = 6443
  }
}

resource "ibm_is_security_group_rule" "kube_api_lb_sg_http_out" {
  group     = local.kube_api_lb_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "kube_api_lb_sg_https_out" {
  group     = local.kube_api_lb_sg[0].id
  direction = "outbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 443
    port_max = 443
  }
}

# sg-openshift-net
# TCP (IN) 	30000-32767 	192.168.200.0/24
# UDP (IN) 	30000-32767 	192.168.200.0/24
# UDP (IN) 	500 	192.168.200.0/24
# UDP (IN) 	9000-9999 	192.168.200.0/24
# TCP (IN) 	9000-9999 	192.168.200.0/24
# TCP (IN) 	10250 	192.168.200.0/24

resource "ibm_is_security_group_rule" "openshift_net_sg_r1_in_tcp" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 30000
    port_max = 32767
  }
}

resource "ibm_is_security_group_rule" "openshift_net_sg_r1_in_udp" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 30000
    port_max = 32767
  }
}

resource "ibm_is_security_group_rule" "openshift_net_sg_500" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 500
    port_max = 500
  }
}

resource "ibm_is_security_group_rule" "openshift_net_sg_r2_in_tcp" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 9000
    port_max = 9999
  }
}

resource "ibm_is_security_group_rule" "openshift_net_sg_r2_in_udp" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  udp {
    port_min = 9000
    port_max = 9999
  }
}

resource "ibm_is_security_group_rule" "openshift_net_sg_10250_out" {
  group     = local.openshift_net_sg[0].id
  direction = "inbound"
  remote    = var.powervs_machine_cidr
  tcp {
    port_min = 10250
    port_max = 10250
  }
}
