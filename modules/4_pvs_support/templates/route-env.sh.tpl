################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# sets up the interface routes
INT_IFACE=""
ip -o -f inet addr show | grep ${subnet} | awk '{print $$2}' | while read IFACE
do
echo "$${IFACE} found"
cat << EOF | nmcli connection edit "$${IFACE}"
goto ipv4
%{ for cidr in cidrs_ipv4 ~}
set routes ${cidr} ${gateway}
%{ endfor ~}
save
quit
EOF

nmcli connection up "$${IFACE}"
break
fi
done