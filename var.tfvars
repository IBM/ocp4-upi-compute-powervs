### IBM Cloud
ibmcloud_api_key = "4VQ132GBdfr-WewEPtbkgr9FI-Oc_6ZCiRLNfeTgKpHd"

vpc_name   = "rdr-multi-ca-ocp414-zrbg9-vpc"
vpc_region = "jp-osa"
vpc_zone   = "jp-osa-3"

# VPC
#vpc_name   = "rdr-multi-ca-ocp414-zrbg9-vpc"
#vpc_region = "jp-osa"
#vpc_zone   = "jp-osa-3"

# OpenShift Cluster
openshift_api_url        = "https://api.rdr-multi-ca-ocp414.ocp-multiarch.xyz:6443"
openshift_user           = "kubeadmin"
openshift_pass           = "uJiMa-qQzJQ-xhirV-KQ7ef"
openshift_client_tarball = "https://mirror.openshift.com/pub/openshift-v4/multi/clients/ocp-dev-preview/4.14.0-ec.3/ppc64le/openshift-client-linux.tar.gz"
cluster_id               = "99ca11"

# PowerVS
#powervs_service_instance_id = "e612d63e-60e8-4b43-b41b-b3502777dffb"
#powervs_service_instance_id = "4b625fa8-551c-4629-84fa-5d114d3c0d5c"
powervs_service_instance_id  = "b7d90e4a-3d01-490c-984f-61b1ed19959d"
#powervs_region              = "osa"
#powervs_zone                = "osa21"

# Power Instance Configuration
processor_type = "shared"
system_type    = "e980"

name_prefix = "rdr-ca-pvs1"
node_prefix = "rdr-ca-pvs1"

# Machine Details
bastion_health_status = "WARNING"
bastion               = { memory = "16", processors = "1", "count" = 1 }
worker                = { memory = "16", processors = "1", "count" = 1 }

# Images for Power Systems
rhel_image_name = "CentOS-Stream-8"

# Public and Private Key for Bastion Nodes
public_key_file  = "data/id_rsa.pub"
private_key_file = "data/id_rsa"

rhcos_import_image                 = true
rhcos_import_image_filename        = "rhcos-414-92-202307050443-0-ppc64le-powervs.ova.gz"
rhcos_import_image_region_override = "us-east"

