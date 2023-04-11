### IBM Cloud details
ibmcloud_api_key    = "<key>"
ibmcloud_region     = "<region>"
ibmcloud_zone       = "<zone>"
service_instance_id = "<cloud_instance_ID>"

# Machine Details
worker = { memory = "16", processors = "0.5", "count" = 1 }

ignition_file = "data/worker.ign"

rhcos_image_name = "rhcos-4.13"

# PowerVS configuration
processor_type = "shared"
system_type    = "s922"
network_name   = "ocp-net"