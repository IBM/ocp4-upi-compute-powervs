interface=env2
except-interface=lo
bind-dynamic
log-dhcp

dhcp-range=${local.range_start_ip},${local.range_end_ip},${local.mask}
dhcp-option=baremetal,121,0.0.0.0/0,${local.ext_ip},${local.int_ip},${local.ext_ip}
dhcp-hostsfile=/var/lib/dnsmasq/dnsmasq.hostsfile