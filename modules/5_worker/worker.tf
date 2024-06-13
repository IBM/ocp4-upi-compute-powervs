################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

locals {
  ignition_ip = cidrhost(var.powervs_machine_cidr, 3)
}

# Modeled off the OpenShift Installer work for IPI PowerVS
# https://github.com/openshift/installer/blob/master/data/data/powervs/bootstrap/vm/main.tf#L41
# https://github.com/openshift/installer/blob/master/data/data/powervs/cluster/master/vm/main.tf
resource "ibm_pi_instance" "worker" {
  count = var.worker["count"]

  pi_cloud_instance_id = var.powervs_service_instance_id
  pi_instance_name     = "${var.name_prefix}-worker-${count.index}"

  pi_sys_type   = var.system_type
  pi_proc_type  = var.processor_type
  pi_memory     = var.worker["memory"]
  pi_processors = var.worker["processors"]
  pi_image_id   = var.rhcos_image_id

  pi_network {
    network_id = var.powervs_dhcp_network_id
  }

  pi_key_pair_name = var.key_name
  pi_health_status = "WARNING"

  ### DEV NOTE
  # need a different worker.ign with static ip setting a kernel arg using ignition following this pattern:
  # ip={{ item.ipaddr }}::{{ static_ip.gateway }}:{{ static_ip.netmask }}:{{ infraID.stdout }}-{{ item.name }}:ens192:off:{{ coredns_vm.ipaddr }}
  pi_user_data = base64encode(
    templatefile(
      "${path.cwd}/modules/5_worker/templates/worker.ign",
      {
        ignition_ip : "${local.ignition_ip}",
        name : base64encode("${var.name_prefix}-worker-${count.index}"),
  }))

  lifecycle { ignore_changes = [pi_user_data] }
}
