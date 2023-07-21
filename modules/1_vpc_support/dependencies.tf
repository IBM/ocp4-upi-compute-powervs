################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Cross code dependencies

locals {
  public_key_file = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : "${path.cwd}/${var.public_key_file}"
  public_key      = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

# Loads the Security Groups so we can avoid duplication
data "ibm_is_security_groups" "supp_vm_sgs" {
  vpc_id = data.ibm_is_vpc.vpc.id
}