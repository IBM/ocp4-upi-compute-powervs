[vmhost]
%{ for ip in bastion_ip ~}
127.0.0.1 ansible_connection=ssh ansible_user=${rhel_username}
%{ endfor ~}