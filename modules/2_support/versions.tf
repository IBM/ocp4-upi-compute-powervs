################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.53.0"
    }

  }
  required_version = ">= 1.4.0"
}
