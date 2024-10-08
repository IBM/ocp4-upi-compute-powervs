This automation is used in CI/CD only. It is not intended for production use.

Automation : Moving etcd to an attached volume.

Pre-requisites:
This script requires that external block volume of following specification is attached to the Master node of OCP Cluster.
Size : Min 20 GB.
Profile : 5iops-tier
Auto-Delete : True

Note for using Virtual Device: 
We used the External block volumes for testing purpose and found that it is attached as Virtual Device. 
Hence the script mentions /dev/vd*.
Please refer article for other options of external drives.(SCSI/SATA/NVM)

Artifacts: 
Script : mount_etcd_ext_volume.sh 
MachineConfig.yaml : 98-master-lib-etcd-mc.yaml 

Input Parameters:
Tier : Can be either "10iops-tier" or "5iops-tier"
Resource group: Will be specific to Customer(ocp-dev-resource-group in our case)
Tag : Optional
VPC Prefix : Used by the Customer


Steps to run Automation:
  1. CI/CD will take care of backing up the existing etcd data.
  2. CI/CD will add the MachineConfig Yaml file into the OCP Cluster and the MachineConfig CR will move the etcd to the attached block volume.
  3. If the logs show an exit code of 77, then a failure moving the etcd data in /etc/find-secondary-device happened.
  
Please refer the article for more details:
https://docs.openshift.com/container-platform/4.16/scalability_and_performance/recommended-performance-scale-practices/recommended-etcd-practices.html#move-etcd-different-disk_recommended-etcd-practices
