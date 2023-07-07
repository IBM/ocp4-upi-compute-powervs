################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.1"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "~> 2.1.3"
    }
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.54.0"
    }
  }
  required_version = ">= 1.4.0"
}
