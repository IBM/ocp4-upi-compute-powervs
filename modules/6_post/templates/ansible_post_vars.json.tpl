# This file is used to provide variables to ansible-playbook
node_labels: {
  "topology.kubernetes.io/region": "${region}",
  "topology.kubernetes.io/zone": "${zone}",
  "failure-domain.beta.kubernetes.io/region": "${region}",
  "failure-domain.beta.kubernetes.io/zone": "${zone}",
  "vpc-block-csi-driver-labels": "",
  "node.kubernetes.io/instance-type": "${system_type}"
}

# NFS Storage variables
nfs_server: "${nfs_server}"
nfs_path: "${nfs_path}"

