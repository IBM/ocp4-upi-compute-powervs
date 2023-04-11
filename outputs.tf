################################################################
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2023
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################

output "worker_private_ip" {
  value = join(", ", data.ibm_pi_instance_ip.worker_ip.*.ip)
}

output "worker_public_ip" {
  value = join(", ", data.ibm_pi_instance_ip.worker_public_ip.*.external_ip)
}

output "gateway_ip" {
  value = data.ibm_pi_network.network.gateway
}

output "cidr" {
  value = data.ibm_pi_network.network.cidr
}

output "public_cidr" {
  value = ibm_pi_network.public_network.pi_cidr
}