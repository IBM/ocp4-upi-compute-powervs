# ocp4-upi-compute-powervs

The `ocp4-upi-compute-powervs` [project](https://github.com/ibm/ocp4-upi-compute-powervs) provides Terraform based automation code to help with the deployment of OpenShift Container Platform (OCP) 4.x compute workers on [IBM® Power Systems™ Virtual Server on IBM Cloud](https://www.ibm.com/cloud/power-virtual-server).

## Prerequisites

1. Requires Terraform v1.4.0 or Higher
2. A PowerVS Service
3. An RHCOS Image loaded to the PowerVS Service
4. An Existing OpenShift Container Platform Cluster (on Power or Intel VPC)
5. A downloaded ignition file stored (in data folder)

```
❯ curl -k http://api.demo.ocp-power.xyz:22624/config/worker -o worker.ign
```

or

```
❯ oc extract -n openshift-machine-api secret/worker-user-data --keys=userData --to=-
```

## Commands

### Init 

### Plan

### Apply 

### Destroy


# Support
Is this a Red Hat or IBM supported solution?

No. This is only an early alpha version of a mixed architecture compute.

This notice will be removed when the feature is generally available or in Tech Preview. 