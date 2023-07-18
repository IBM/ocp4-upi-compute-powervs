%{ for cidr in cidrs_ipv4 ~}
${cidr} via 192.168.200.1
%{ endfor ~}