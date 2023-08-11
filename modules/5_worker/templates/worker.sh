#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This file is a shortcut to generate the contents in the worker.ign

# v1: tx-checksumming off / restarts wait-online
# Content: IyEvYmluL2Jhc2gKaWYgWyAiIiA9ICJlbnYzIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIC9zYmluL2V0aHRvb2wgLS1vZmZsb2FkIGVudjMgdHgtY2hlY2tzdW1taW5nIG9mZgogIHN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lLnNlcnZpY2UgCmZpCg==

#v2: missing details for interface and action 
# Content: aWYgWyAiIiA9ICJlbnYzIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIC9zYmluL2V0aHRvb2wgLS1vZmZsb2FkIGVudjMgdHgtY2hlY2tzdW1taW5nIG9mZgogIHN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lLnNlcnZpY2UgCmVsc2UgCiAgImVjaG8gIm5vdCBydW5uaW5nIHR4LWNoZWNrc3VtbWluZyBvZmYiCmZpCg==
cat << EOF | base64 --wrap=0
if [ "$1" = "env3" ] && [ "$2" = "up" ]
then
  /sbin/ethtool --offload env3 tx-checksumming off
  systemctl restart NetworkManager-wait-online.service 
else 
  "echo "not running tx-checksumming off"
fi
EOF
echo ""
