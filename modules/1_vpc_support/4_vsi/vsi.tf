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

resource "ibm_is_instance" "supp_vm_vsi" {
  count = 1

  name    = "${var.vpc_name}-supp-vsi"
  vpc     = var.vpc_id
  zone    = var.zone
  keys    = [var.key_id]
  image   = data.ibm_is_image.supp_vm_image[0].id
  profile = "ox2-2x16"
  # Profiles: https://cloud.ibm.com/docs/vpc?topic=vpc-profiles&interface=ui
  # Uses a storage optimized compute profile

  resource_group = var.resource_group

  primary_network_interface {
    subnet          = var.subnet
    security_groups = [var.sg_id, var.cp_internal_sg_id]
  }

  user_data = templatefile("${path.cwd}/modules/1_vpc_support/4_vsi/templates/cloud-init.yaml.tpl", {})

  lifecycle {
    ignore_changes = [image]
  }
}

resource "ibm_is_floating_ip" "supp_vm_fip" {
  count          = var.vpc_supp_public_ip ? 1 : 0
  resource_group = var.resource_group
  name           = "${var.vpc_name}-supp-floating-ip"
  target         = ibm_is_instance.supp_vm_vsi[0].primary_network_interface[0].id
}

