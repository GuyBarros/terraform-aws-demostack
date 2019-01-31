#!/usr/bin/env bash
set -e

echo "==> Nomad (server)"

echo "--> Fetching"
install_from_url "nomad" "${nomad_url}"

echo "--> Generating Vault token..."
export VAULT_TOKEN="$(consul kv get service/vault/root-token)"
  NOMAD_VAULT_TOKEN="$(VAULT_TOKEN="$VAULT_TOKEN" \
  VAULT_ADDR="https://active.vault.service.consul:8200" \
  VAULT_SKIP_VERIFY=true \
  vault token create -field=token -policy=superuser -period=72h)"

consul kv put service/vault/nomad-token $NOMAD_VAULT_TOKEN

echo "--> Writing configuration"
sudo mkdir -p /mnt/nomad
sudo mkdir -p /etc/nomad.d
sudo tee /etc/nomad.d/config.hcl > /dev/null <<EOF
name         = "${node_name}"
data_dir     = "/mnt/nomad"
enable_debug = true

bind_addr = "0.0.0.0"

advertise {
  http = "${node_name}.node.consul:4646"
  rpc  = "${node_name}.node.consul:4647"
  serf = "${node_name}.node.consul:4648"
}

server {
  enabled          = true
  bootstrap_expect = ${nomad_servers}
  encrypt          = "${nomad_gossip_key}"
}

client {
  enabled = true
   options {
    "driver.raw_exec.enable" = "1"
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

vault {
  enabled          = true
  address          = "https://active.vault.service.consul:8200"
  ca_file          = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file        = "/etc/ssl/certs/me.crt"
  key_file         = "/etc/ssl/certs/me.key"
  create_from_role = "nomad-cluster"
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
Environment=VAULT_TOKEN=$NOMAD_VAULT_TOKEN
ExecStart=/usr/local/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable nomad
sudo systemctl start nomad
sleep 2

echo "--> Waiting for all Nomad servers"
while [ "$(nomad server-members 2>&1 | grep "alive" | wc -l)" -lt "${nomad_servers}" ]; do
  sleep 5
done

echo "--> Waiting for Nomad leader"
while [ -z "$(curl -s http://${node_name}.node.consul:4646/v1/status/leader)" ]; do
  sleep 5
done

echo "==> Nomad is done!"
