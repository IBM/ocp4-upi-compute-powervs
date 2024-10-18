################################################################
# Copyright 2024 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# sets up the interface routes
ip route show | grep ${subnet} | grep -v via | awk '{print $3}' | uniq | while read IFACE
do
echo "$${IFACE} found"
cat << EOF | nmcli connection edit "System $${IFACE}"
goto ipv4
%{ for cidr in cidrs_ipv4 ~}
set routes ${cidr} ${gateway}
%{ endfor ~}
save
quit
EOF

nmcli connection up "System $${IFACE}"
break
done