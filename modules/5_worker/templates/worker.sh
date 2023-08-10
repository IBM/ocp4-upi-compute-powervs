#!/usr/bin/env bash

################################################################
# Copyright 2023 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# This file is a shortcut to generate the contents in the worker.ign

# v1: tx-checksumming off / restarts wait-online
# Content: IyEvYmluL2Jhc2gKaWYgWyAiIiA9ICJlbnYzIiBdICYmIFsgIiIgPSAidXAiIF0KdGhlbgogIC9zYmluL2V0aHRvb2wgLS1vZmZsb2FkIGVudjMgdHgtY2hlY2tzdW1taW5nIG9mZgogIHN5c3RlbWN0bCByZXN0YXJ0IE5ldHdvcmtNYW5hZ2VyLXdhaXQtb25saW5lLnNlcnZpY2UgCmZpCg==

cat << EOF | base64 --wrap=0
if [ "" = "env3" ] && [ "" = "up" ]
then
  /sbin/ethtool --offload env3 tx-checksumming off
fi
systemctl restart NetworkManager-wait-online.service 
EOF
echo ""
