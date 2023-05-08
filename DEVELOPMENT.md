# Development 
The code is built with Terraform, Ansible and Shell Scripts.

## Architecture

This architecture augments an existing IBM VPC hosted Red Hat OpenShift Container Platform cluster with workers hosted on IBM PowerVS. The approach uses the ignition file from the existing cluster in order to boot Red Hat CoreOS with the cluster's MachineConfigPool `worker`.

This architecture only adds compute plane workers.

![arch](./docs/img/arch.png)

## Steps

1. 

## Dependencies

**Providers**

The automation code uses the following providers:

1. [ibm-cloud/ibm](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs) to deploy a work on a Power Systems Virtual Server Instance.
2. [hashicorp/random](https://registry.terraform.io/providers/hashicorp/random/latest/docs) sets a random id for the 
3. [hashicorp/null](https://registry.terraform.io/providers/hashicorp/null/latest/docs) we may use this in the future to sign the CSR on the bastion
4. [community-terraform-providers/ignition](https://registry.terraform.io/providers/community-terraform-providers/ignition/latest/docs) [git](https://github.com/community-terraform-providers/terraform-provider-ignition)

**Ansible**

The code uses Ansible Playbooks: 

1. [ocp4-helpernode](https://github.com/redhat-cop/ocp4-helpernode) to set up an "all-in-one" support instance that has all the infrastructure/services in order to install OpenShift.
2. [ocp4-playbooks](https://github.com/ocp-power-automation/ocp4-playbooks) to create the ignition and to monitor OCP installation progress and configure the cluster nodes as defined in vars.yaml.

## Limitations

1. Number of VPCs per Region

> Each OpenShift Container Platform cluster creates its own VPC. The default quota of VPCs per region is 10 and will allow 10 clusters. To have more than 10 clusters in a single region, you must increase this quota.

2. The Cloud Init is limited to 65K in lenght the Ignition file is longer than 65k, and needs to use source to point to the source.

## References
1. [Installing a cluster on IBM Power](https://docs.openshift.com/container-platform/4.12/installing/installing_ibm_power/installing-ibm-power.html)
2. [Configuring multi-architecture compute machines on an OpenShift cluster | Post-installation configuration](https://docs.openshift.com/container-platform/4.12/post_installation_configuration/multi-architecture-configuration.html)