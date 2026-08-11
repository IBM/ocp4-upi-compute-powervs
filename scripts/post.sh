# Setup RMC

# Setup Localized NFS backed by VPC CSI




# Remove all worker taints
oc adm taint node ${NAME_PREFIX}-worker-${IDX} node.cloudprovider.kubernetes.io/uninitialized- \

Approve and Issue certificates