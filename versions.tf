################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = "1.54444.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "~> 2.1.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
  }
  required_version = ">= 1.4.0"
}
