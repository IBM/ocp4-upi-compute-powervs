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
    ibm = {
      source                = "IBM-Cloud/ibm"
      version               = "~> 1.57.0"
      configuration_aliases = [ibm]
    }
  }
  required_version = ">= 1.5.0"
}
