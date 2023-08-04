#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

DIRNAME="$(dirname -- ${BASH_SOURCE[0]})"

echo "Creating the nfs pod"
oc new-project nfs-test
oc create -f ${DIRNAME}/nfs.yaml

echo "Checking the pod"
sleep 5
echo "amd64: exit status"
oc get pod test-pod-amd64 -o yaml | yq -r '.status.containerStatuses[0].state.terminated'
echo "ppc64le: exit status"
oc get pod test-pod-ppc64le -o yaml | yq -r '.status.containerStatuses[0].state.terminated'
