#!/usr/bin/env bash

echo "==> getting the aws metadata token"
export TOKEN=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

echo "==> check token was set"
echo $TOKEN

echo "--> clean up any default config."
sudo rm  /etc/nomad.d/*



echo "NOMAD --> Waiting for Vault to be active"
VAULT_ADDR="https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
URL="$VAULT_ADDR/v1/sys/health"
HTTP_STATUS=0

echo "Vault API ADDRESS:" $VAULT_ADDR

while [[ $HTTP_STATUS -ne 200 && $HTTP_STATUS -ne 473 && $HTTP_STATUS -ne 429 ]]; do
  HTTP_STATUS=$(curl -k -o /dev/null -w "%%{http_code}" $URL)
  sleep 1
done



export CONSUL_HTTP_ADDR=http://$(private_ip):8500

echo "--> Generating Vault token..."
export VAULT_TOKEN="$(consul kv get service/vault/root-token)"
export NOMAD_VAULT_TOKEN="$(VAULT_TOKEN="$VAULT_TOKEN" \
  VAULT_ADDR="https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8200" \
  VAULT_SKIP_VERIFY=true \
  vault token create -field=token -policy=superuser -policy=nomad-server -display-name=${node_name} -id=${node_name} -period=72h)"

consul kv put service/vault/${node_name}-token $NOMAD_VAULT_TOKEN


echo "--> Installing CNI plugin"
sudo mkdir -p /opt/cni/bin/
export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
export CNI_PLUGIN_VERSION=${cni_version}
sudo wget "https://github.com/containernetworking/plugins/releases/download/$${CNI_PLUGIN_VERSION}/cni-plugins-linux-$${ARCH_CNI}-$${CNI_PLUGIN_VERSION}".tgz && \
sudo tar -xzf cni-plugins-linux-$${ARCH_CNI}-$${CNI_PLUGIN_VERSION}.tgz -C /opt/cni/bin/

export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -fsq http://169.254.169.254/latest/meta-data/placement/availability-zone |  sed 's/[a-z]$//')
export AWS_AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)


echo "--> Writing configuration"
sudo mkdir -p /mnt/nomad
sudo mkdir -p /etc/nomad.d


echo "--> clean up any default config."
sudo rm  /etc/nomad.d/*

echo "--> creating directories for host volumes"
sudo mkdir -p /etc/nomad.d/host-volumes/wp-runner
sudo mkdir -p /etc/nomad.d/host-volumes/wp-server


sudo tee /etc/nomad.d/nomad.hcl > /dev/null <<EOF
name         = "${node_name}"
data_dir     = "/mnt/nomad"
enable_debug = true
bind_addr = "0.0.0.0"
/*
advertise {
  http = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4646"
  rpc  = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4647"
  serf = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4648"
}
*/
datacenter = "$AWS_AZ"
region = "$AWS_REGION"
server {
  enabled          = true
  bootstrap_expect = ${nomad_servers}
  encrypt          = "${nomad_gossip_key}"
}
client {
  enabled = true

  cni_path = "opt/cni/bin"
  cni_config_dir = "opt/cni/config"


  host_volume wp-server-vol {
      path = "/etc/nomad.d/host-volumes/wp-server"
      read_only = false
    }
  host_volume wp-runner-vol {
      path = "/etc/nomad.d/host-volumes/wp-runner"
      read_only = false
    }
  

   options {
    "driver.raw_exec.enable" = "1"
     "docker.privileged.enabled" = "true"
      "qemu.config.image_paths"  = "/tmp"
  }
  meta {
    "type" = "server",
    "name" = "${node_name}"
  }

}
tls {
  rpc  = true
  http = true
  ca_file   = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file = "/etc/ssl/certs/me.crt"
  key_file  = "/etc/ssl/certs/me.key"
  verify_server_hostname = false
}
consul {
    address = "localhost:8500"
    server_service_name = "nomad-server"
    client_service_name = "nomad-client"
    auto_advertise = true
    server_auto_join = true
    client_auto_join = true
}
vault {
  enabled          = true
  tls_skip_verify  = true
  address          = "https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
  ca_file          = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file        = "/etc/ssl/certs/me.crt"
  key_file         = "/etc/ssl/certs/me.key"
  # create_from_role = "nomad-cluster"
  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}
autopilot {
    cleanup_dead_servers = true
    last_contact_threshold = "200ms"
    max_trailing_logs = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones = false
    disable_upgrade_migration = false
    enable_custom_upgrades = false
}
telemetry {
  publish_allocation_metrics = true
  publish_node_metrics = true
  prometheus_metrics = true
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/nomad.sh > /dev/null <<"EOF"
alias noamd="nomad"
alias nomas="nomad"
alias nomda="nomad"
export NOMAD_ADDR="https://${node_name}.node.consul:4646"
export NOMAD_CACERT="/usr/local/share/ca-certificates/01-me.crt"
export NOMAD_CLIENT_CERT="/etc/ssl/certs/me.crt"
export NOMAD_CLIENT_KEY="/etc/ssl/certs/me.key"
EOF
source /etc/profile.d/nomad.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]

ExecStart=/usr/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536
#Enterprise License
Environment=NOMAD_LICENSE=${nomadlicense}
Environment=VAULT_TOKEN="$(echo $NOMAD_VAULT_TOKEN)"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable nomad
sudo systemctl start nomad
sleep 5

echo "--> Waiting for Nomad leader"
while ! curl  -k https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4646/v1/status/leader --show-error; do
  sleep 2
done

echo "--> Waiting for a list of Nomad peers"
while ! curl  -k https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4646/v1/status/peers --show-error; do
  sleep 2
done

echo "--> Waiting for all Nomad servers"
while [ "$(nomad server members 2>&1 | grep "alive" | wc -l)" -lt "${nomad_servers}" ]; do
  sleep 5
done

echo "--> Configure Nomad WIF"

echo "--> Retrieving root token..."
 export VAULT_TOKEN=$(consul kv get service/vault/root-token)
  export VAULT_ADDR="https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
  export VAULT_SKIP_VERIFY=true
##################
echo "==> Configure Nomad WIF"

echo "--> mounting nomad jwt auth method"
{
vault auth enable -path 'jwt-nomad' 'jwt'

 }||
{
  echo "--> nomad jwt auth method already exists, moving on"
}

echo "--> configuring nomad jwt auth method"
{
sudo tee vault-auth-method-jwt-nomad.json > /dev/null <<"EOF"
{
  "jwks_url": "https://nomad-server.service.consul:4646/.well-known/jwks.json",
  "jwt_supported_algs": ["RS256", "EdDSA"],
  "default_role": "nomad-workloads"
}
EOF

vault write auth/jwt-nomad/config '@vault-auth-method-jwt-nomad.json'

 }||
{
  echo "--> nomad jwt auth method already configured, moving on"
}

echo "--> configuring nomad jwt auth method role"
{

sudo tee vault-role-nomad-workloads.json > /dev/null <<"EOR"
{
  "role_type": "jwt",
  "bound_audiences": ["vault.io"],
  "user_claim": "/nomad_job_id",
  "user_claim_json_pointer": true,
  "claim_mappings": {
    "nomad_namespace": "nomad_namespace",
    "nomad_job_id": "nomad_job_id",
    "nomad_task": "nomad_task"
  },
  "token_type": "service",
  "token_policies": ["nomad-workloads"],
  "token_period": "30m",
  "token_explicit_max_ttl": 0
}
EOR

vault write auth/jwt-nomad/role/nomad-workloads '@vault-role-nomad-workloads.json'

 }||
{
  echo "--> nomad jwt auth method role already configured, moving on"
}

echo "--> configuring nomad-workloads vault policy"
{
vault policy write nomad-workloads - <<EOR
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
  }

  path "kv/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/test/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "pki/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# all access to boundary namespace
path "boundary/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/data/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "kv/data/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "kv/metadata/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_namespace}}/*" {
  capabilities = ["list"]
}

path "kv/metadata/*" {
  capabilities = ["list"]
}

EOR

 }||
{
  echo "--> nomad-workloads vault policy already exists, moving on"
}

echo "==> Nomad WIF is done!"

echo "==> Nomad is done!"
