################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache2.0
################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.ibmcloud_region
  zone             = var.ibmcloud_zone
}

# Create a random_id label
resource "random_id" "label" {
  count       = 1
  byte_length = "2" # Since we use the hex, the word lenght would double
}

locals {
  # Generates resource prefix as combination of (random_id) + (resource_name)
  name_prefix = random_id.label[0].hex
}

data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = var.service_instance_id
}

data "ibm_pi_network" "network" {
  pi_network_name      = var.network_name
  pi_cloud_instance_id = var.service_instance_id
}

data "ibm_pi_image" "worker" {
  count                = 1
  pi_image_name        = var.rhcos_image_name
  pi_cloud_instance_id = var.service_instance_id
}

resource "ibm_pi_network" "public_network" {
  pi_network_name      = "${local.name_prefix}-worker-pub-net"
  pi_cloud_instance_id = var.service_instance_id
  pi_network_type      = "pub-vlan"
  pi_dns               = [for dns in split(";", var.dns_forwarders) : trimspace(dns)]
}

locals {
  catalog_worker_image = [for x in data.ibm_pi_catalog_images.catalog_images.images : x if x.name == var.rhcos_image_name]
  worker_image_id      = length(local.catalog_worker_image) == 0 ? data.ibm_pi_image.worker[0].id : local.catalog_worker_image[0].image_id
  worker_storage_pool  = length(local.catalog_worker_image) == 0 ? data.ibm_pi_image.worker[0].storage_pool : local.catalog_worker_image[0].storage_pool
}

# Build the ignition file so it points back to the control plane
data "ignition_file" "w_hostname" {
  count     = var.worker["count"]
  overwrite = true
  mode      = "420" // 0644
  path      = "/etc/hostname"
  content {
    content = <<EOF
worker-${count.index}.ocp-power.xyz
EOF
  }
}

data "ignition_config" "worker" {
  count = var.worker["count"]
  merge {
    source = "http://${var.ignition_hostname}:22624/config/worker"
  }
  files = [data.ignition_file.w_hostname[count.index].rendered]
}

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  pi_memory        = var.worker["memory"]
  pi_processors    = var.worker["processors"]
  pi_instance_name = "${local.name_prefix}-worker"

  pi_proc_type = var.processor_type
  pi_image_id  = local.worker_image_id
  pi_sys_type  = var.system_type

  pi_cloud_instance_id = var.service_instance_id
  pi_storage_pool      = local.worker_storage_pool

  pi_network {
    network_id = ibm_pi_network.public_network.network_id
  }
  pi_network {
    network_id = data.ibm_pi_network.network.id
  }

  pi_key_pair_name = var.public_key_name
  pi_health_status = "WARNING"

  pi_user_data = base64encode(data.ignition_config.worker[count.index].rendered)
}

# The PowerVS instance may take a few minutes to start (per the IPI work)
resource "time_sleep" "wait_3_minutes" {
  depends_on      = [ibm_pi_instance.worker]
  create_duration = "3m"
}

data "ibm_pi_instance_ip" "worker" {
  count      = 1
  depends_on = [time_sleep.wait_3_minutes]

  pi_instance_name     = ibm_pi_instance.worker[count.index].pi_instance_name
  pi_network_name      = data.ibm_pi_network.network.pi_network_name
  pi_cloud_instance_id = var.service_instance_id
}

data "ibm_pi_instance_ip" "worker_public_ip" {
  count      = 1
  depends_on = [time_sleep.wait_3_minutes]

  pi_instance_name     = ibm_pi_instance.worker[count.index].pi_instance_name
  pi_network_name      = ibm_pi_network.public_network.pi_network_name
  pi_cloud_instance_id = var.service_instance_id
}
