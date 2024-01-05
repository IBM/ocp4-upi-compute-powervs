#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

for FILE in $(find $(pwd)/../ -iname 'versions.tf' -exec grep -rn ibm {} \; | awk -F ':' '{print $1}' | sort -u)
do
echo "FILE: ${FILE}"
node update-version.js ${FILE} > ${FILE}.tmp
mv ${FILE}.tmp ${FILE}
done