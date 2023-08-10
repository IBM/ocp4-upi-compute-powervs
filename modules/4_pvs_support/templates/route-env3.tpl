%{ for cidr in cidrs_ipv4 ~}
${cidr} via ${gateway}
%{ endfor ~}