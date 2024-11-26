#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Helper file to generate the var.tfvars file

# The following environment variables need to be set:
# IC_API_KEY or IBMCLOUD_API_KEY - the ibm cloud api key
# INSTALL_CONFIG_FILE - path to the install config file
# POWERVS_SERVICE_INSTANCE_ID - the workspace instance id
# KUBECONFIG - the path to the kubeconfig
# PUBLIC_KEY_FILE - the path to the public key file
# PRIVATE_KEY_FILE - the path to the private key file
# RHEL_IMAGE_NAME - the name of the Centos/RHEL image to use as the bastion in PowerVS.

# Requires:
# - Path to install-config.yaml
# - Path to kubeconfig
# - Path to id_rsa / id_rsa.pub
# - Command: openshift-install
# - Command: ibmcloud
# - Command: yq
# - Command: jq
EXPECTED_NODES=$2
if [ -z "${EXPECTED_NODES}" ]
then
    EXPECTED_NODES=1
fi

CLEAN_VERSION="${3}"

IBMCLOUD=ibmcloud
if [[ $(type -t ic) == function ]]
then
    IBMCLOUD=ic
else 
    ${IBMCLOUD} plugin install power-iaas -f
fi

if [ ! -z "${1}" ]
then
    IBMCLOUD_HOME_FOLDER="${1}"
    function ic() {
    HOME=${IBMCLOUD_HOME_FOLDER} ibmcloud "$@"
    }
    IBMCLOUD=ic
fi

# format file var.tfvars
create_var_file () {

# API IBMCLOUD VPC pattern
if [ -z "${IC_API_KEY}" ]
then
    # PowerVS Pattern
    export IC_API_KEY="${IBMCLOUD_API_KEY}"
    if [ -z "${IC_API_KEY}" ]
    then
        echo "ERROR: Should fail.... IC_API_KEY needs to be set"
        return
    fi
fi

# VPC Update
if [ -z "${INSTALL_CONFIG_FILE}" ]
then
    echo "ERROR: missing install-config.yaml"
    return
else
    VPC_REGION=$(yq -r '.platform.ibmcloud.region' ${INSTALL_CONFIG_FILE})
    VPC_ZONE=$(yq -r '.controlPlane.platform.ibmcloud.zones[0]' ${INSTALL_CONFIG_FILE})

    VPC_NAME_PREFIX=$(yq -r '.metadata.name' ${INSTALL_CONFIG_FILE})
    VPC_NAME=$(${IBMCLOUD} is vpcs --output json | jq -r '.[] | select(.name | contains("'${VPC_NAME_PREFIX}'")).name')
fi

if [ -z "${POWERVS_SERVICE_INSTANCE_ID}" ]
then
    echo "ERROR: Should fail.... POWERVS_SERVICE_INSTANCE_ID needs to be set"
    echo "From the newly created workspace"
    return
else
    # Dev Note: The original approach scanned the service-instances which is paged.
    # We must search for the CRN
    POWERVS_ZONE=$(${IBMCLOUD} resource service-instance "${POWERVS_SERVICE_INSTANCE_ID}" --output json | jq -r '.[].region_id')
    POWERVS_REGION=$(
        case "$POWERVS_ZONE" in
            ("dal10") echo "dal" ;;
            ("dal12") echo "dal" ;;
            ("us-south") echo "us-south" ;;
            ("wdc06") echo "wdc" ;;
            ("us-east") echo "us-east" ;;
            ("sao01") echo "sao" ;;
            ("tor01") echo "tor" ;;
            ("mon01") echo "mon" ;;
            ("mad01") echo "mad" ;;
            ("eu-de-1") echo "eu-de" ;;
            ("eu-de-2") echo "eu-de" ;;
            ("lon04") echo "lon" ;;
            ("lon06") echo "lon" ;;
            ("syd04") echo "syd" ;;
            ("syd05") echo "syd" ;;
            ("tok04") echo "tok" ;;
            ("osa21") echo "osa" ;;
            (*) echo "$POWERVS_ZONE" ;;
        esac)
    echo "REGION: ${POWERVS_REGION}"
    echo "ZONE: ${POWERVS_ZONE}"
fi

# OpenShift URL
if [ -z "${KUBECONFIG}" ]
then 
    echo "ERROR: kubeconfig is not set"
    return
else
    OPENSHIFT_API_URL=$(cat "${KUBECONFIG}" | yq -r '.clusters[].cluster.server')
    cp "${KUBECONFIG}" data/kubeconfig
fi

if [ -z "${PUBLIC_KEY_FILE}" ]
then
    echo "ERROR: PUBLIC KEY FILE is not set"
    return
fi
if [ -z "${PRIVATE_KEY_FILE}" ]
then
    echo "ERROR: PRIVATE KEY FILE is not set"
    return
fi
cp "${PUBLIC_KEY_FILE}" data/id_rsa.pub
cp "${PRIVATE_KEY_FILE}" data/id_rsa

# Check to see if the outside is setting the TARBALL's location
if [ -z "${OPENSHIFT_CLIENT_TARBALL}" ]
then
    # Stable is fine.
    OPENSHIFT_CLIENT_TARBALL=https://mirror.openshift.com/pub/openshift-v4/multi/clients/ocp/stable/ppc64le/openshift-client-linux.tar.gz
fi

# rhcos_import_image_filename        = "rhcos-414-92-202307050443-0-ppc64le-powervs.ova.gz"
COREOS_URL=$(openshift-install coreos print-stream-json | jq -r '.architectures.ppc64le.artifacts.powervs.formats."ova.gz".disk.location')
COREOS_FILE=$(echo ${COREOS_URL} | sed 's|/| |g' | awk '{print $NF}')
COREOS_NAME=$(echo ${COREOS_FILE} | sed 's|\.ova\.gz||' | tr '.' '-' | sed 's|-0-powervs-ppc64le||g')

# RHEL_IMAGE_NAME
if [ -z "${RHEL_IMAGE_NAME}" ]
then
    echo "WARNING: RHEL_IMAGE_NAME is not set, defaulting to 'Centos-Stream-9'"
    RHEL_IMAGE_NAME="Centos-Stream-9"
fi

OVERRIDE_PREFIX=$(${IBMCLOUD} pi workspace list 2>&1 | grep $POWERVS_SERVICE_INSTANCE_ID | awk '{print $NF}')

# SKIP_VPC_KEY is conditionally switched
${IBMCLOUD} pi ssh-key create cicd-key-$(date +%s) --key "$(<data/id_rsa.pub)" || true
${IBMCLOUD} is key-create cicd-key @data/id_rsa.pub  || true

# Set the Machine Type
if [[ "${POWERVS_REGION}" == "wdc06" ]]
then
    MACHINE_TYPE="s922"
else
    # Default (original s1022)
    MACHINE_TYPE="s922"
fi
echo "MACHINE_TYPE=${MACHINE_TYPE}"

# creates the var file
cat << EOFXEOF > data/var.tfvars
ibmcloud_api_key = "${IC_API_KEY}"

vpc_name   = "${VPC_NAME}"
vpc_region = "${VPC_REGION}"
vpc_zone   = "${VPC_ZONE}"

powervs_service_instance_id = "${POWERVS_SERVICE_INSTANCE_ID}"
powervs_region              = "${POWERVS_REGION}"
powervs_zone                = "${POWERVS_ZONE}"

openshift_api_url        = "${OPENSHIFT_API_URL}"

openshift_client_tarball = "${OPENSHIFT_CLIENT_TARBALL}"
rhel_image_name  = "${RHEL_IMAGE_NAME}"
rhcos_image_name = "${COREOS_NAME}"
public_key_file  = "data/id_rsa.pub"
private_key_file = "data/id_rsa"

# Example file name: rhcos-414-92-202307050443-0-ppc64le-powervs.ova.gz
rhcos_import_image                 = true
rhcos_import_image_filename        = "${COREOS_NAME}-0-ppc64le-powervs.ova.gz"
rhcos_import_image_region_override = "us-east"

processor_type = "shared"
system_type    = "${MACHINE_TYPE}"
bastion_health_status = "OK"
bastion               = { memory = "16", processors = "1", "count" = 1 }
worker                = { memory = "16", processors = "1", "count" = ${EXPECTED_NODES} }
override_region_check=true

mac_tags = [ "mac-cicd-${CLEAN_VERSION}" ]

cicd = true
cicd_disable_defrag = true
cicd_etcd_secondary_disk=true

skip_vpc_key = true
setup_transit_gateway = false
transit_gateway_name = "multi-arch-comp-${POWERVS_ZONE}-1-tg"
EOFXEOF
}

create_var_file
