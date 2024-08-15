#!/usr/bin/env bash
echo "==> Consul (client)"


echo "==> getting the aws metadata token"
export TOKEN=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

echo "==> check token was set"
echo $TOKEN



echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d

echo "--> clean up any default config."
sudo rm  /etc/consul.d/*

#"client_addr": "$(private_ip) 127.0.0.1",
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "datacenter": "${region}",
  "advertise_addr": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)",
  "advertise_addr_wan": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)",
  "client_addr": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4) 127.0.0.1",
  "data_dir": "/mnt/consul",
  "encrypt": "${consul_gossip_key}",
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value} addr_type=private_v4"],
  "server": false,
  "ports":{
    "http": 8500,
    "https": 8501,
    "grpc": 8502,
    "grpc_tls": 8503
  },
   "ui_config":{
  "enabled" : true
},
  "connect":{
    "enabled": true
  },

"autopilot": {
"redundancy_zone_tag" : "zone",
    "cleanup_dead_servers": true,
    "last_contact_threshold": "200ms",
    "max_trailing_logs": 250,
    "server_stabilization_time": "10s",
    "disable_upgrade_migration": false
  },
  "telemetry": {
    "disable_hostname": true,
    "prometheus_retention_time": "30s"
  }
}
EOF


# Set up ACLs.
cat <<EOF > /etc/consul.d/acl.hcl
acl = {
  enabled = true
  default_policy = "allow"
  enable_token_persistence = true
  tokens {
    initial_management = "${consul_master_token}"
  }
  down_policy = "extend-cache"
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
ExecStart=/usr/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
#Enterprise License
Environment=CONSUL_LICENSE=${consullicense}
Environment=CONSUL_HTTP_TOKEN=${consul_master_token}

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl start consul

export CONSUL_HTTP_ADDR=http://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8500

echo "--> setting up resolv.conf"
##################################
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

mkdir /etc/systemd/resolved.conf.d
touch /etc/systemd/resolved.conf.d/forward-consul-domains.conf

IPV4=$(ec2metadata --local-ipv4)

printf "[Resolve]\nDNS=127.0.0.1\nDomains=~consul\n" > /etc/systemd/resolved.conf.d/forward-consul-domains.conf

iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A OUTPUT -d localhost -p udp -m udp --dport 53 -j REDIRECT --to-ports 8600
iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 53 -j REDIRECT --to-ports 8600

systemctl daemon-reload
systemctl restart systemd-resolved

 sleep 3

##################################

echo "==> Consul is done!"
