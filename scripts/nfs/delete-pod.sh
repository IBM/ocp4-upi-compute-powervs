#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

DIRNAME="$(dirname -- ${BASH_SOURCE[0]})"
oc delete -f ${DIRNAME}/nfs.yaml
oc delete project nfs-test