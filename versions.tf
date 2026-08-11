################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 2.5.0"
    }
<<<<<<< HEAD
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.6.1"
    }
=======
>>>>>>> 114d672 (refactor: update code to v2 and simplify the content)
  }
  required_version = ">= 1.14.0"
}
