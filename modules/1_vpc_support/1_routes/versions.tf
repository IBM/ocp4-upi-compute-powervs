################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

terraform {
  required_providers {
    ibm = {
      source                = "IBM-Cloud/ibm"
      version               = "~> 1.69.1"
      configuration_aliases = [ibm]
    }
  }
  required_version = ">= 1.5.0"
}





