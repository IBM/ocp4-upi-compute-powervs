#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# Moves the route script to the right interface

cidrs=("${1}")
for cidr in "${cidrs[@]}"
do
  envs=($(ip r | grep "$cidr dev" | awk '{print $3}'))
  for env in "${envs[@]}"
  do
    dev_name=$(sudo nmcli -t -f DEVICE connection show | grep $env)
    if [ "${dev_name}" != "env3" ]
    then
      mv -f /etc/sysconfig/network-scripts/route-env3 /etc/sysconfig/network-scripts/route-${dev_name}
      nmcli device up ${dev_name}
      echo "device is up"
    else 
      echo "same device"
    fi
  done
done