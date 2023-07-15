################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Based on reference https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf

locals {
  public_key_file = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : "${path.cwd}/${var.public_key_file}"
  public_key      = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

data "ibm_is_ssh_keys" "keys" {
  # Region is implicit
}

locals {
  ky = [for x in data.ibm_is_ssh_keys.keys.keys : x if endswith(x.name, "${var.vpc_name}-keypair")]
}

resource "ibm_is_ssh_key" "vpc_support_ssh_key_cond_create" {
  count          = local.ky == [] ? 1 : 0
  name           = "${var.vpc_name}-keypair"
  public_key     = local.public_key
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

data "ibm_is_ssh_key" "vpc_support_ssh_key" {
  name = "${var.vpc_name}-keypair"
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

# Loads the Security Groups so we can avoid duplication
data "ibm_is_security_groups" "supp_vm_sgs" {
  vpc_id = data.ibm_is_vpc.vpc.id
}

locals {
  sgs = [for x in data.ibm_is_security_groups.supp_vm_sgs.security_groups : x.id if x.name == "${var.vpc_name}-supp-sg"]
}

resource "ibm_is_security_group" "supp_vm_sg" {
  count = local.sgs == [] ? 1 : 0

  name           = "${var.vpc_name}-supp-sg"
  vpc            = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_is_vpc.vpc.resource_group
}

data "ibm_is_security_group" "supp_vm_sg_refresh" {
  depends_on = [ibm_is_security_group.supp_vm_sg]
  name       = "${var.vpc_name}-supp-sg"
}

locals {
  sg_id = data.ibm_is_security_group.supp_vm_sg_refresh.id
}

# allow all outgoing network traffic
resource "ibm_is_security_group_rule" "supp_vm_sg_outgoing_all" {
  count     = 1
  group     = local.sg_id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "supp_vm_sg_ssh_all" {
  count     = 1
  group     = local.sg_id
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
  group     = local.sg_id
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
  group     = local.sg_id
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
  group     = local.sg_id
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
  group     = local.sg_id
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
  group     = local.sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 111
    port_max = 111
  }
}

# allow all incoming network traffic on port 53
resource "ibm_is_security_group_rule" "supp_vm_sg_supp_all" {
  count     = 1
  group     = local.sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

# allow all incoming network traffic for ping
resource "ibm_is_security_group_rule" "supp_vm_sg_ping_all" {

  count     = 1
  group     = local.sg_id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
    code = 1
  }
}

data "ibm_is_image" "supp_vm_image" {
  count = 1
  name  = var.supp_vm_image_name
}

data "ibm_is_instances" "vsis" {
  vpc_name = var.vpc_name
}

locals {
  vsis = [for x in data.ibm_is_instances.vsis.instances : x if x.id == "${var.vpc_name}-supp-vsi"]
}

resource "ibm_is_instance" "supp_vm_vsi" {
  # Create if it doesn't exist
  count      = local.vsis == [] ? 1 : 2
  depends_on = [data.ibm_is_ssh_key.vpc_support_ssh_key]

  name    = "${var.vpc_name}-supp-vsi"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = data.ibm_is_vpc.vpc.subnets[0].zone
  keys    = [data.ibm_is_ssh_key.vpc_support_ssh_key.id]
  image   = data.ibm_is_image.supp_vm_image[0].id
  profile = "cx2d-8x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Originally used cx2-2x4, however 8x16 includes 300G storage.

  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[0].id
    security_groups = [local.sg_id]
  }

  user_data = templatefile("${path.cwd}/modules/1_vpc_support/templates/cloud-init.yaml.tpl", {
    domain : split("//", split(":", var.openshift_api_url)[0])[0],
  })
}