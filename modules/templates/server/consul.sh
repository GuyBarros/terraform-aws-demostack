#!/usr/bin/env bash

echo "==> getting the aws metadata token"
export TOKEN=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

echo "==> check token was set"
echo $TOKEN

echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo mkdir -p /etc/consul.d/acl_policies

echo "--> clean up any default config."
sudo rm  /etc/consul.d/*


sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "datacenter": "${region}",
  "bootstrap_expect": ${consul_servers},
  "advertise_addr": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)",
  "advertise_addr_wan": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)",
  "client_addr": "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4) 127.0.0.1",
  "data_dir": "/mnt/consul",
  "encrypt": "${consul_gossip_key}",
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value} addr_type=private_v4"],
  "server": true,
  "ports":{
    "http": 8500,
    "https": 8501,
    "grpc": 8502,
    "grpc_tls": 8503
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


# Enable ACLs with deny default — matches the server ACL configuration.
# Clients must NOT use initial_management (server-only); use default so the
# agent can authenticate until the per-worker agent token is applied below.
cat <<EOF > /etc/consul.d/acl.hcl
acl = {
  enabled = true
  default_policy = "deny"
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
export CONSUL_HTTP_ADDR=http://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8500


echo "--> setting up ACL system"
############################################

# Per-node server policy — broad write access needed for demo server operations.
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

# Anonymous policy — read-only access for service discovery and UI browsing without a token.
sudo tee /etc/consul.d/acl_policies/anonymous.hcl > /dev/null <<"POLICYEOF"
node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "read"
}

query_prefix "" {
  policy = "read"
}
POLICYEOF

# Vault policy — allows Vault to register its service and manage its KV path.
sudo tee /etc/consul.d/acl_policies/vault-service.hcl > /dev/null <<"POLICYEOF"
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service "vault" {
  policy = "write"
}

session_prefix "" {
  policy = "write"
}

key_prefix "service/vault" {
  policy = "write"
}
POLICYEOF

# Nomad server policy — allows Nomad servers to register services and access shared KV paths.
sudo tee /etc/consul.d/acl_policies/nomad-server.hcl > /dev/null <<"POLICYEOF"
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

key_prefix "service/vault" {
  policy = "read"
}

key_prefix "service/nomad" {
  policy = "write"
}

key_prefix "service/consul" {
  policy = "read"
}
POLICYEOF

# Nomad client policy — allows Nomad worker agents to register job services.
sudo tee /etc/consul.d/acl_policies/nomad-client.hcl > /dev/null <<"POLICYEOF"
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}
POLICYEOF

echo "--> Waiting for all Consul servers"
while [ "$(consul members 2>&1 | grep "server" | grep "alive" | wc -l)" -lt "${consul_servers}" ]; do
  sleep 3
done

echo "--> Waiting for Consul leader #1 "
while [ -z "$(curl -skfS http://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8500/v1/status/leader)" ]; do
  sleep 3
done

# Create per-node agent policy and token. Policy create is idempotent via fallback to update.
consul acl policy create -name consul_${node_name} -rules @/etc/consul.d/acl_policies/${node_name}.hcl || \
  consul acl policy update -name consul_${node_name} -rules @/etc/consul.d/acl_policies/${node_name}.hcl
consul acl token create -format=json -description "consul ${node_name} agent token" -policy-name consul_${node_name} > /etc/consul.d/consul_${node_name}_token.json

# Apply the per-node agent token so this agent can register itself and services.
AGENT_TOKEN=$(jq -r '.SecretID' /etc/consul.d/consul_${node_name}_token.json)
if [ -z "$AGENT_TOKEN" ] || [ "$AGENT_TOKEN" = "null" ]; then
  echo "ERROR: failed to obtain agent token for ${node_name}" >&2
  exit 1
fi
consul acl set-agent-token agent "$AGENT_TOKEN"

# On server-0: create shared service tokens for Vault, Nomad, and the anonymous token.
if [ "${node_name}" == "${namespace}-server-0" ]; then
  echo "--> Creating shared ACL policies and tokens"

  # Vault service registration token
  consul acl policy create -name vault-service \
    -rules @/etc/consul.d/acl_policies/vault-service.hcl || echo "--> vault-service policy already exists"
  VAULT_CONSUL_TOKEN=$(consul acl token create -format=json \
    -description "Vault service registration token" \
    -policy-name vault-service | jq -r '.SecretID')
  consul kv put service/consul/vault-token "$VAULT_CONSUL_TOKEN"

  # Nomad server token
  consul acl policy create -name nomad-server \
    -rules @/etc/consul.d/acl_policies/nomad-server.hcl || echo "--> nomad-server policy already exists"
  NOMAD_SERVER_CONSUL_TOKEN=$(consul acl token create -format=json \
    -description "Nomad server Consul token" \
    -policy-name nomad-server | jq -r '.SecretID')
  consul kv put service/consul/nomad-server-token "$NOMAD_SERVER_CONSUL_TOKEN"

  # Nomad client token
  consul acl policy create -name nomad-client \
    -rules @/etc/consul.d/acl_policies/nomad-client.hcl || echo "--> nomad-client policy already exists"
  NOMAD_CLIENT_CONSUL_TOKEN=$(consul acl token create -format=json \
    -description "Nomad client Consul token" \
    -policy-name nomad-client | jq -r '.SecretID')
  consul kv put service/consul/nomad-client-token "$NOMAD_CLIENT_CONSUL_TOKEN"

  # Apply anonymous policy to the built-in anonymous token so the UI is browsable without login.
  consul acl policy create -name anonymous \
    -rules @/etc/consul.d/acl_policies/anonymous.hcl || \
    consul acl policy update -name anonymous \
      -rules @/etc/consul.d/acl_policies/anonymous.hcl
  consul acl token update \
    -id 00000000-0000-0000-0000-000000000002 \
    -description "Anonymous Token" \
    -policy-name anonymous

  echo "--> Consul shared service tokens stored in KV"
fi

##################################

echo "--> setting up resolv.conf"
##################################
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

mkdir -p /etc/systemd/resolved.conf.d
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

echo "--> Waiting for all Consul servers"
while [ "$(consul members 2>&1 | grep "server" | grep "alive" | wc -l)" -lt "${consul_servers}" ]; do
  sleep 3
done

echo "--> Waiting for Consul leader #2"
while [ -z "$(curl -skfS http://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8500/v1/status/leader)" ]; do
  sleep 3
done


#########

echo "==> Consul is done!"
