################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Creates a Support Machine for the VPC and PowerVS integration
# Ref: https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/dns/dns.tf


data "ibm_is_image" "supp_vm_image" {
  count = 1
  name  = var.supp_vm_image_name
}

data "ibm_is_instances" "vsis" {
  vpc_name = var.vpc_name
}

locals {
  vsis = [for x in data.ibm_is_instances.vsis.instances : x if x.name == "${var.vpc_name}-supp-vsi"]
}

resource "ibm_is_instance" "supp_vm_vsi" {
  # Create if it doesn't exist
  count = local.vsis == [] ? 1 : 0

  name    = "${var.vpc_name}-supp-vsi"
  vpc     = data.ibm_is_vpc.vpc.id
  zone    = data.ibm_is_vpc.vpc.subnets[0].zone
  keys    = [local.key_id]
  image   = data.ibm_is_image.supp_vm_image[0].id
  profile = "cx2d-8x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Originally used cx2-2x4, however 8x16 includes 300G storage.

  resource_group = data.ibm_is_vpc.vpc.resource_group

  primary_network_interface {
    subnet          = data.ibm_is_vpc.vpc.subnets[0].id
    security_groups = [local.sg_id, local.cp_internal_sg[0].id]
  }

  user_data = templatefile("${path.cwd}/modules/1_vpc_support/templates/cloud-init.yaml.tpl", {})
}

resource "ibm_is_floating_ip" "supp_vm_fip" {
  resource_group = data.ibm_is_vpc.vpc.resource_group
  count          = local.vsis == [] ? 1 : 0
  name           = "${var.vpc_name}-supp-floating-ip"
  target         = ibm_is_instance.supp_vm_vsi[0].primary_network_interface[0].id
}

