################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# *Design Note*
# Global variables are prefixed with ibmcloud_
# PowerVS variables are prefixed with powervs_
# VPC variables are prefixed with vpc_

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key associated with user's identity"
  default     = "<key>"
}

################################################################
# Configure the IBM PowerVS provider
################################################################

variable "powervs_service_instance_id" {
  type        = string
  description = "The PowerVS service instance ID of your account"
  default     = ""
}

variable "powervs_region" {
  type        = string
  description = "The IBM Cloud region where you want to create the workers"
  default     = ""
}

variable "powervs_zone" {
  type        = string
  description = "The zone of an IBM Cloud region where you want to create Power System workers"
  default     = ""
}

################################################################
# Configure the IBM VPC provider
################################################################

variable "vpc_name" {
  type        = string
  description = "The name of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_region" {
  type        = string
  description = "The region of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

variable "vpc_zone" {
  type        = string
  description = "The zone of an IBM Cloud VPC where OCP cluster is running"
  default     = ""
}

################################################################
# The OpenShift Cluster details
################################################################

variable "openshift_api_url" {
  type        = string
  description = "The API URL of the OpenShift Cluster"
  default     = "https://api.example.ocp-multiarch.xyz:6443"
}

variable "openshift_user" {
  type        = string
  description = "The user of the OpenShift Cluster"
  default     = ""
}

variable "openshift_pass" {
  type        = string
  description = "The pass of the OpenShift Cluster"
  default     = ""
}

################################################################
# The PowerVS Instance configuration settings
################################################################

variable "processor_type" {
  type        = string
  description = "The type of processor mode (shared/dedicated)"
  default     = "shared"
}

# Reference https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-about-virtual-server
# The default is e980.
variable "system_type" {
  type        = string
  description = "The type of system (s922/e980)"
  default     = "e980"
}

################################################################
# Configure the PowerVS instance bastion details
################################################################

variable "bastion" {
  type = object({ count = number, memory = string, processors = string })
  default = {
    count      = 1
    memory     = "16"
    processors = "1"
  }
  validation {
    condition     = lookup(var.bastion, "count", 1) >= 1 && lookup(var.bastion, "count", 1) <= 2
    error_message = "The bastion.count value must be either 1 or 2."
  }
}

variable "bastion_health_status" {
  type        = string
  description = "Specify if bastion should poll for the Health Status to be OK or WARNING. Default is OK."
  default     = "WARNING"
  validation {
    condition     = contains(["OK", "WARNING"], var.bastion_health_status)
    error_message = "The bastion_health_status value must be either OK or WARNING."
  }
}

# Centos default is CentOS-Stream-8
variable "rhel_image_name" {
  type        = string
  description = "Name of the RHEL image that you want to use for the bastion node"
  default     = "rhel-8.6"
}

variable "rhel_username" {
  type    = string
  default = "root"
}

variable "rhel_subscription_username" {
  type    = string
  default = ""
}

variable "rhel_subscription_password" {
  type    = string
  default = ""
}

variable "rhel_subscription_org" {
  type    = string
  default = ""
}

variable "rhel_subscription_activationkey" {
  type    = string
  default = ""
}

# SMT level is 8 which is the maximum.
variable "rhel_smt" {
  type        = number
  description = "SMT value to set on the bastion node. Eg: on,off,2,4,8"
  default     = 8
}

################################################################
# Configure the PowerVS workers to be added to the compute plane
################################################################

variable "worker" {
  type = object({ count = number, memory = string, processors = string })
  default = {
    count      = 1
    memory     = "16"
    processors = "1"
  }
  validation {
    condition     = lookup(var.worker, "count", 1) >= 1
    error_message = "The worker.count value must be greater than 1."
  }
}

################################################################
# RHCOS PowerVS Details
################################################################

variable "rhcos_image_name" {
  type        = string
  description = "Name of the rhcos image that you want to use for the workers"
  default     = "rhcos-4.14"
}

variable "rhcos_import_image" {
  type        = bool
  description = "Set to true to upload RHCOS image to PowerVS from Cloud Object Storage."
  default     = false
}

variable "rhcos_import_image_filename" {
  type        = string
  description = "Name of the RHCOS image object file. This file is expected to be in .ova.gz format"
  default     = "rhcos-414-92-202307050443-0-ppc64le-powervs.ova.gz"
}

variable "rhcos_import_image_storage_type" {
  type        = string
  description = "Storage type in PowerVS where the RHCOS image needs to be uploaded"
  default     = "tier1"
}

### RHCOS Instance Details

variable "rhcos_pre_kernel_options" {
  type        = list(string)
  description = "List of kernel arguments for the cluster nodes that for pre-installation"
  default     = []
}

variable "rhcos_kernel_options" {
  type        = list(string)
  description = "List of kernel arguments for the cluster nodes"
  default     = []
}

################################################################
# IBM Cloud DirectLink configuration variables
################################################################

variable "ibmcloud_dl_endpoint_net_cidr" {
  type        = string
  description = "IBM Cloud DirectLink endpoint network cidr eg. 10.0.0.0/8"
  default     = ""
}

################################################################
### OpenShift variables
################################################################

variable "openshift_install_tarball" {
  type    = string
  default = "https://mirror.openshift.com/pub/openshift-v4/multi/clients/ocp/stable/ppc64le/openshift-install-linux.tar.gz"
}

variable "openshift_client_tarball" {
  type    = string
  default = "https://mirror.openshift.com/pub/openshift-v4/multi/clients/ocp/stable/ppc64le/openshift-client-linux.tar.gz"
}

variable "release_image_override" {
  type    = string
  default = ""
}

# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
variable "cluster_domain" {
  type        = string
  default     = "ibm.com"
  description = "Domain name to use to setup the cluster. A DNS Forward Zone should be a registered in IBM Cloud if use_ibmcloud_services = true"

  validation {
    condition     = can(regex("^[a-z0-9]+[a-zA-Z0-9_\\-.]*[a-z0-9]+$", var.cluster_domain))
    error_message = "The cluster_domain value must be a lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character."
  }
}
# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Should not be more than 14 characters
variable "cluster_id_prefix" {
  type    = string
  default = "test-ocp"

  validation {
    condition     = can(regex("^$|^[a-z0-9]+[a-zA-Z0-9_\\-.]*[a-z0-9]+$", var.cluster_id_prefix))
    error_message = "The cluster_id_prefix value must be a lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.cluster_id_prefix) <= 14
    error_message = "The cluster_id_prefix value shouldn't be greater than 14 characters."
  }
}
# Must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character
# Length cannot exceed 14 characters when combined with cluster_id_prefix
variable "cluster_id" {
  type    = string
  default = ""

  validation {
    condition     = can(regex("^$|^[a-z0-9]+[a-zA-Z0-9_\\-.]*[a-z0-9]+$", var.cluster_id))
    error_message = "The cluster_id value must be a lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character."
  }

  validation {
    condition     = length(var.cluster_id) <= 14
    error_message = "The cluster_id value shouldn't be greater than 14 characters."
  }
}

variable "use_zone_info_for_names" {
  type        = bool
  default     = true
  description = "Add zone info to instance name or not"
}

################################################################
# Additional Settings
################################################################
variable "ssh_agent" {
  type        = bool
  description = "Enable or disable SSH Agent. Can correct some connectivity issues. Default: false"
  default     = false
}

variable "connection_timeout" {
  description = "Timeout in minutes for SSH connections"
  default     = 30
}

variable "helpernode_repo" {
  type        = string
  description = "Set the repo URL for using ocp4-helpernode"
  default     = "https://github.com/redhat-cop/ocp4-helpernode"
  # Repo for running ocp4 installations steps.
}

variable "helpernode_tag" {
  type        = string
  description = "Set the branch/tag name or commit# for using ocp4-helpernode repo"
  default     = "adb1102f64b2f25a8a1b44a96c414f293d72d3fc"
  # Checkout level for var.helpernode_repo which is used for setting up services required on bastion node
}

variable "install_playbook_repo" {
  type        = string
  description = "Set the repo URL for using ocp4-playbooks"
  default     = "https://github.com/ocp-power-automation/ocp4-playbooks"
  # Repo for running ocp4 installations steps.
}

variable "install_playbook_tag" {
  type        = string
  description = "Set the branch/tag name or commit# for using ocp4-playbooks repo"
  default     = "main"
  # Checkout level for var.install_playbook_repo which is used for running ocp4 installations steps
}

variable "ansible_extra_options" {
  type        = string
  description = "Extra options string to append to ansible-playbook commands"
  default     = "-v"
}

variable "ansible_repo_name" {
  default = "ansible-2.9-for-rhel-8-ppc64le-rpms"
}

variable "private_network_mtu" {
  type        = number
  description = "MTU value for the private network interface on RHEL and RHCOS nodes"
  default     = 1500
}

variable "installer_log_level" {
  type        = string
  description = "Set the log level required for openshift-install commands"
  default     = "info"
}

variable "public_key_name" {
  type    = string
  default = "<none>"
}

variable "powervs_dns_forwarders" {
  type    = string
  default = "8.8.8.8;8.8.4.4"
}

variable "node_labels" {
  type        = map(string)
  description = "Map of node labels for the cluster nodes"
  default     = {}
}

variable "setup_snat" {
  type        = bool
  description = "IMPORTANT: This is an experimental feature. Flag to configure bastion as SNAT and use the router on all cluster nodes"
  default     = true
}

variable "nfs_server" {
  type        = string
  description = "IP address of existing NFS Server"
  default     = "none"
}

variable "nfs_path" {
  type        = string
  description = "Path on NFS Server where storage is mounted"
  default     = "/export"
}

##########################################

variable "public_key_file" {
  type        = string
  description = "Path to public key file"
  default     = "data/id_rsa.pub"
  # if empty, will default to ${path.cwd}/data/id_rsa.pub
}

variable "private_key_file" {
  type        = string
  description = "Path to private key file"
  default     = "data/id_rsa"
  # if empty, will default to ${path.cwd}/data/id_rsa
}

variable "private_key" {
  type        = string
  description = "content of private ssh key"
  default     = ""
  # if empty, will read contents of file at var.private_key_file
}

variable "public_key" {
  type        = string
  description = "Public key"
  default     = ""
  # if empty, will read contents of file at var.public_key_file
}

###
variable "name_prefix" {
  type    = string
  default = ""
  validation {
    condition     = length(var.name_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for name_prefix."
  }
}

variable "node_prefix" {
  type    = string
  default = ""
  validation {
    condition     = length(var.node_prefix) <= 32
    error_message = "Length cannot exceed 32 characters for node_prefix."
  }
}

###
locals {
  private_key_file = var.private_key_file == "" ? "${path.cwd}/data/id_rsa" : var.private_key_file
  public_key_file  = var.public_key_file == "" ? "${path.cwd}/data/id_rsa.pub" : var.public_key_file
  private_key      = var.private_key == "" ? file(coalesce(local.private_key_file, "/dev/null")) : var.private_key
  public_key       = var.public_key == "" ? file(coalesce(local.public_key_file, "/dev/null")) : var.public_key
}

### Development Specific Triggers
variable "ansible_support_version" {
  type        = string
  description = "Trigger for ansible code refresh"
  default     = "1"
}

variable "workers_version" {
  type        = string
  description = "Trigger for workers to be rebuilt via version change"
  default     = "1"
}

### OpenShift Configuration
variable "kubeconfig_file" {
  type        = string
  description = "Path to kubeconfig file"
  default     = "data/kubeconfig"
}

################################################################
# Overrides the Region Check
################################################################

variable "override_region_check" {
  type        = bool
  description = "Set to true if you want to skip region checks."
  default     = false
}
