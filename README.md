# ocp4-upi-compute-powervs

The [`ocp4-upi-compute-powervs` project](https://github.com/ibm/ocp4-upi-compute-powervs) provides Terraform based automation code to help with the deployment of OpenShift Container Platform (OCP) 4.x compute workers on [IBM® Power Systems™ Virtual Server on IBM Cloud](https://www.ibm.com/cloud/power-virtual-server).

## Prerequisites

1. Requires Terraform v1.5.0 to v1.5.5
2. A PowerVS Workspace on IBM Cloud enabled with [Power Edge Router](https://cloud.ibm.com/docs/power-iaas?topic=power-iaas-per). The legacy Cloud Connection is only in the `release-4.14` and `release-4.15` branches, and is not maintained.
3. An RHCOS Image loaded to the PowerVS Service
4. Optional: An Centos Image loaded to the PowerVS Service
5. An Existing OpenShift Container Platform Cluster installed on IBMCloud VPC with Intel architecture.

## Commands

### Init 

```
❯ terraform init -upgrade
```

### Plan

Copy the `var.tfvars` into a sub-folder data/

Edit for your usage

```
❯ terraform plan -var-file=data/var.tfvars
```

Note: The PowerVS and IBMCloud VPC regions must be compatible.

### Apply 

```
❯ terraform apply -var-file=data/var.tfvars
```

### Destroy

```
❯ terraform destroy -var-file=data/var.tfvars
```

Note, the `destroy` command removes the Node resource, removes the NFS deployment, and destroys the virtual servers. Please backup your NFS Server first - it is destroyed.

## Cluster Details

There are some important points to mention:

1. The Power Bastion node uses a https proxy to forward requests to the Cluster's internal api load balancer. This setting is configured in /etc/environment on the Power Bastion.
2. NFS is used as the storage provider across nodes.

## Running Automation from another IBMCloud VPC

To run the code, you'll need to set the MTU for your machine: 

```
ip link set eth0 mtu 1400
```

### Getting the IPs of Power Workers

To get the IPs of the Power Workers. 

```
❯ oc get nodes -l 'kubernetes.io/arch=ppc64le' -owide
NAME                STATUS   ROLES    AGE   VERSION           INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                                                       KERNEL-VERSION                  CONTAINER-RUNTIME
mac-d263-worker-0   Ready    worker   40h   v1.27.4+4e87926   192.168.200.10   <none>        Red Hat Enterprise Linux CoreOS 414.92.202308151250-0 (Plow)   5.14.0-284.25.1.el9_2.ppc64le   cri-o://1.27.1-6.rhaos4.14.gitc2c9f36.el9
```

## Contributing

If you have any questions or issues you can create a new [issue here][issues].

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

All source files must include a Copyright and License header. The SPDX license header is 
preferred because it can be easily scanned.

If you would like to see the detailed LICENSE click [here](LICENSE).

```text
#
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
#
```

# Support
Is this a Red Hat or IBM supported solution?

No. This is only an early alpha version of multi-architecture compute.

This notice will be removed when the feature is generally available or in Tech Preview. 
