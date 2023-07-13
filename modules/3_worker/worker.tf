################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  pi_memory        = var.worker["memory"]
  pi_processors    = var.worker["processors"]
  pi_instance_name = "${var.name_prefix}-worker-${count.index}"

  pi_proc_type = var.processor_type
  pi_image_id  = local.worker_image_id
  pi_sys_type  = var.system_type

  pi_cloud_instance_id = var.service_instance_id

  pi_network {
    network_id = data.ibm_pi_network.network.id
  }

  pi_key_pair_name = var.public_key_name
  pi_health_status = "WARNING"

  pi_user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/3_worker/templates/worker.ign",
      { ignition_url : var.ignition_url,
        name : base64encode("${var.name_prefix}-worker-${count.index}"),
  }))
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
  count      = var.worker["count"]
  depends_on = [time_sleep.wait_3_minutes]

  pi_instance_name     = ibm_pi_instance.worker[count.index].pi_instance_name
  pi_network_name      = data.ibm_pi_network.network.pi_network_name
  pi_cloud_instance_id = var.service_instance_id
}
