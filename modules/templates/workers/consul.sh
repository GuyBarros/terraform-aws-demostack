#!/usr/bin/env bash
set -e

echo "==> Consul (client)"

echo "==> Consul (server)"
if [ ${enterprise} == 0 ]
then
echo "--> Fetching OSS binaries"
install_from_url "consul" "${consul_url}"
else
echo "--> Fetching enterprise binaries"
install_from_url "consul" "${consul_ent_url}"
fi

echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "datacenter": "${region}",
  "advertise_addr": "$(private_ip)",
  "bind_addr": "0.0.0.0",
  "client_addr": "0.0.0.0",
  "data_dir": "/mnt/consul",
  "encrypt": "${consul_gossip_key}",
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value}"],
  "ports": {
    "http": 8500,
    "https": 8501,
    "grpc": 8502
  },
 "ui": true,
 "key_file": "/etc/ssl/certs/me.key",
  "cert_file": "/etc/ssl/certs/me.crt",
  "ca_file": "/usr/local/share/ca-certificates/01-me.crt",
  "verify_incoming": true,
  "verify_outgoing": false,
  "verify_server_hostname": false,
  "verify_incoming_rpc": true,
  "encrypt_verify_incoming": false,
  "encrypt_verify_outgoing": false,
   "auto_encrypt": {
    "allow_tls": true,
    "tls": true
  },
  "enable_agent_tls_for_checks":true,
 "connect":{
  "enabled": true,
  "ca_provider":"consul",
  "ca_config": {
  "private_key": "/etc/ssl/certs/me.key",
  "root_cert": "/usr/local/share/ca-certificates/01-me.crt"
  }
      },
      "autopilot": {
    "cleanup_dead_servers": true,
    "last_contact_threshold": "200ms",
    "max_trailing_logs": 250,
    "server_stabilization_time": "10s",
    "redundancy_zone_tag": "",
    "disable_upgrade_migration": false,
    "upgrade_version_tag": "build"
},
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<"EOF"
alias conslu="consul"
alias ocnsul="consul"
EOF
source /etc/profile.d/consul.sh





echo "--> Making consul.d world-writable..."
sudo chmod 0777 /etc/consul.d/

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul
Documentation=https://www.consul.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl start consul

echo "--> Installing dnsmasq"
ssh-apt install dnsmasq
sudo tee /etc/dnsmasq.d/10-consul > /dev/null <<"EOF"
server=/consul/127.0.0.1#8600
no-poll
server=8.8.8.8
server=8.8.4.4
cache-size=0
EOF
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

echo "--> Writting default Mesh proxy configs"
consul config write -<<EOF
{
  "Kind": "proxy-defaults",
  "Name": "global",
  "MeshGateway": {
    "Mode": "local"
  }
}
EOF


echo "==> Consul is done!"
