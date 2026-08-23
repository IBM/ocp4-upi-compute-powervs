#!/bin/bash

# ################################################################
# Post Worker Creation

# 1. Setup RMC
# TODO: https://github.com/ocp-power-automation/ocp4-playbooks/blob/main/playbooks/roles/ocp-customization/tasks/powervm_rmc.yaml
# Setup RMC using `oc` not Ansible

# 2. Setup Localized NFS backed by VPC CSI
# TODO: This may not be needed

# 3. Remove all worker taints
# Note: not officially supported.
for NODE in $(oc get nodes -l kubernetes.io/arch=ppc64le -l node-role.kubernetes.io/worker= -oname)
do
    oc adm taint ${NODE} node.cloudprovider.kubernetes.io/uninitialized-
done

Approve and Issue certificates