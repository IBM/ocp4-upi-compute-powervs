# This file is used to provide variables to ansible-playbook

# Ref: https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/clusterapi/README.md
# IBM Cloud 	vpc-block-csi-driver-labels 	Used by the IBM Cloud CSI driver as a target for persistent volume node affinity
node_labels: {
  "topology.kubernetes.io/region": "${region}",
  "topology.kubernetes.io/zone": "${zone}",
  "failure-domain.beta.kubernetes.io/region": "${region}",
  "failure-domain.beta.kubernetes.io/zone": "${zone}",
  "vpc-block-csi-driver-labels": "false",
  "node.kubernetes.io/instance-type": "${system_type}"
}

powervs_worker_count: "${powervs_worker_count}"

# NFS Storage variables
nfs_server: "${nfs_server}"
nfs_path: "${nfs_path}"

