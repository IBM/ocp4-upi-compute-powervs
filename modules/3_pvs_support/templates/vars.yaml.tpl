---
ocp_client: "${client_tarball}"
openshift_machine_config_url: "${openshift_machine_config_url}:22623/config/worker"
vpc_support_server_ip: "${vpc_support_server_ip}"
ports:
- 443/tcp
- 80/tcp
- 8080/tcp
- 6443/tcp
- 6443/udp
- 22623/tcp
- 22623/udp
- 9000/tcp
- 69/udp
- 111/tcp
- 2049/tcp
- 20048/tcp
- 50825/tcp
- 53248/tcp
ssh_gen_key: false
