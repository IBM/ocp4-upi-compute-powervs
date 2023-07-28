
#cloud-config
packages:
  - bind
  - bind-utils
  - httpd
  - nfs-utils
  - squid
write_files:
- path: /tmp/named-conf-edit.sed
  permissions: '0640'
  content: |
    /^\s*listen-on port 53 /s/127\.0\.0\.1/127\.0\.0\.1; MYIP/
    /^\s*allow-query /s/localhost/any/
    /^\s*dnssec-validation /s/ yes/ no/
    /^\s*type hint;/s/ hint/ forward/
    /^\s*file\s"named.ca";/d
    /^\s*type forward/a \\tforward only;\n\tforwarders { 161.26.0.7; 161.26.0.8; };
- path: /etc/exports
  permissions: '0640'
  content: |
    /export *(rw)
- path: /etc/squid/squid.conf
  permissions: '0640'
  content: |
    acl localnet src 10.0.0.0/8
    acl localnet src 172.16.0.0/12
    acl localnet src 192.168.0.0/16
    http_access deny !localnet
    http_port 3128
    coredump_dir /var/spool/squid
runcmd:
  - export MYIP=`hostname -I`; sed -i.bak "s/MYIP/$MYIP/" /tmp/named-conf-edit.sed
  - sed -i.orig -f /tmp/named-conf-edit.sed /etc/named.conf
  - systemctl enable named.service nfs-server
  - systemctl start named.service nfs-server
  - mkdir -p /export && chmod -R 777 /export
  - systemctl enable squid
  - systemctl start squid
