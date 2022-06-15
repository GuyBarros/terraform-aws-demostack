#!/usr/bin/env bash

echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/consul.d/acl_policies

echo "--> clean up any default config."
sudo rm  /etc/consul.d/*

#"primary_datacenter":  "${primary_datacenter}", "bind_addr": "0.0.0.0",
# "client_addr": "$(private_ip) 127.0.0.1",
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "datacenter": "${region}",
  "bootstrap_expect": ${consul_servers},
  "advertise_addr": "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)",
  "advertise_addr_wan": "$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)",
  "client_addr": "$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) 127.0.0.1",
  "data_dir": "/mnt/consul",
  "encrypt": "${consul_gossip_key}",
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value} addr_type=private_v4"],
  "server": true,
  "ports":{
    "http": 8500,
    "https": 8501,
    "grpc": 8502
  },
  "connect":{
    "enabled": true
  },
  "ui_config":{
  "enabled" : true
},
"enable_central_service_config":true,

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
  },
  "recursors": ["169.254.169.253","1.1.1.1","1.0.0.1","8.8.8.8"]
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

#######################################################
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
sudo systemctl restart consul

export CONSUL_HTTP_TOKEN=${consul_master_token}
export CONSUL_HTTP_ADDR=http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8500


#TODO - CONSUL ACL Bootstrap
echo "--> setting up ACL system"
############################################
sudo tee /etc/consul.d/acl_policies/${node_name}.hcl > /dev/null <<EOF
node "${node_name}" {
  policy = "write"
}

service_prefix "" {
  policy = "write"
}

query_prefix ""{
  policy = "write"
}

kv "" {
  policy = "write"
}


EOF

sudo tee /etc/consul.d/acl_policies/anonymous.hcl > /dev/null <<EOF
node "${node_name}" {
  policy = "write"
}

service_prefix "" {
  policy = "write"
}

query_prefix ""{
  policy = "write"
}

kv "" {
  policy = "write"
}


EOF

 consul acl policy create -name consul_${node_name} -rules @/etc/consul.d/acl_policies/${node_name}.hcl
 consul acl token create -format=json -description "consul ${node_name} agent token" -policy-name consul_${node_name} > /etc/consul.d/consul_${node_name}_token.json

##################################

echo "--> Waiting for all Consul servers"
while [ "$(consul members 2>&1 | grep "server" | grep "alive" | wc -l)" -lt "${consul_servers}" ]; do
  sleep 3
done

echo "--> Waiting for Consul leader #1 "
while [ -z "$(curl -skfS http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8500/v1/status/leader)" ]; do
  sleep 3
done



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



echo "--> Waiting for Consul leader #2"
while [ -z "$(curl -skfS http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8500/v1/status/leader)" ]; do
  sleep 3
done


#########

echo "==> Consul is done!"
