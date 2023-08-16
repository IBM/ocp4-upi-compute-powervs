# ocp4-upi-compute-powervs

The [`ocp4-upi-compute-powervs` project](https://github.com/ibm/ocp4-upi-compute-powervs) provides Terraform based automation code to help with the deployment of OpenShift Container Platform (OCP) 4.x compute workers on [IBM® Power Systems™ Virtual Server on IBM Cloud](https://www.ibm.com/cloud/power-virtual-server).

## Prerequisites

1. Requires Terraform v1.5.0 or Higher
2. A PowerVS Service 
3. An RHCOS Image loaded to the PowerVS Service
4. Optional: An RHEL/Centos Image loaded to the PowerVS Service
5. An Existing OpenShift Container Platform Cluster installed on IBMCloud VPC.

## Commands

### Init 

```
❯ terraform init -upgrade
```

### Plan

```
❯ terraform plan -var-file=var.tfvars
```

Note: The PowerVS and IBMCloud VPC regions must be compatible.

### Apply 

```
❯ terraform apply -var-file=var.tfvars
```

### Destroy

```
❯ terraform destroy -var-file=var.tfvars
```

Note, the `destroy` command leaves the Node resource in place, and destroys the virtual server. You must delete the Node manually.

## Cluster Details

There are some important points to mention:

1. The Power Bastion node uses a https proxy to forward requests to the Cluster's internal api load balancer. This setting is configured in /etc/environment on the Power Bastion.
2. NFS is used as the storage provider across nodes.

## Running Automation from another IBMCloud VPC

To run the code, you'll need to set the MTU for your machine: 

```
ip link set eth0 mtu 1400
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