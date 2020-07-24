#!/usr/bin/env bash
echo "==> Vault (server)"
# Vault expects the key to be concatenated with the CA
sudo mkdir -p /etc/vault.d/tls/
sudo mkdir -p /opt/vault/raft/
sudo tee /etc/vault.d/tls/vault.crt > /dev/null <<EOF
$(cat /etc/ssl/certs/me.crt)
$(cat /usr/local/share/ca-certificates/01-me.crt)
EOF

# hold for consul servers to all be there
while [ "$(dig consul.service.consul +short | wc -l)" != "${vault_servers}" ]; do
  sleep 3
done

echo "==> checking if we are using enterprise binaries"
echo "==> value of enterprise is ${enterprise}"

if [ ${enterprise} == 0 ]
then
echo "--> Fetching Vault OSS"
install_from_url "vault" "${vault_url}"

else
echo "--> Fetching Vault Ent"
install_from_url "vault" "${vault_ent_url}"
fi


echo "--> Writing configuration"
sudo mkdir -p /etc/vault.d

sudo tee /etc/vault.d/config.hcl > /dev/null <<EOF
cluster_name = "${namespace}-demostack"

service_registration "consul" {
  address = "127.0.0.1:8500"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/tls/vault.crt"
  tls_key_file  = "/etc/ssl/certs/me.key"
   tls-skip-verify = true
}
seal "awskms" {
  region = "${region}"
  kms_key_id = "${kmskey}"
}
telemetry {
  prometheus_retention_time = "30s",
  disable_hostname = true
}

replication {
      resolver_discover_servers = false
}

api_addr = "https://$(public_ip):8200"
# cluster_addr = "https://$(private_ip):8201"
cluster_addr = "https://$(public_ip):8201"
disable_mlock = true
ui = true
EOF

# appending storage
sudo tee -a /etc/vault.d/config.hcl > /dev/null <<EOF
storage "raft" {
  path = "/opt/vault/raft"
  node = "${node_name}"
EOF
servers=$(dig consul.service.consul +short | paste -sd " " -)
for s in $servers; do
sudo tee -a /etc/vault.d/config.hcl > /dev/null <<EOF
  retry_join {
    leader_api_addr = "https://$s:8200"
  }
EOF
done
sudo tee -a /etc/vault.d/config.hcl > /dev/null <<EOF
}
EOF


echo "--> Writing profile"
sudo tee /etc/profile.d/vault.sh > /dev/null <<"EOF"
alias vualt="vault"
export VAULT_ADDR="https://active.vault.service.consul:8200"
EOF
source /etc/profile.d/vault.sh

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config="/etc/vault.d/config.hcl"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable vault
sudo systemctl start vault
sleep 8

echo "--> Initializing vault"
consul lock tmp/vault/lock "$(cat <<"EOF"
set -e
sleep 2
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
if ! vault operator init -status >/dev/null; then
  vault operator init  -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 > /tmp/out.txt
  cat /tmp/out.txt | grep "Recovery Key 1" | sed 's/Recovery Key 1: //' | consul kv put service/vault/recovery-key -
   cat /tmp/out.txt | grep "Initial Root Token" | sed 's/Initial Root Token: //' | consul kv put service/vault/root-token -

export VAULT_TOKEN=$(consul kv get service/vault/root-token)
echo "ROOT TOKEN: $VAULT_TOKEN"

sudo systemctl enable vault
sudo systemctl restart vault
else
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=$(consul kv get service/vault/root-token)
echo "ROOT TOKEN: $VAULT_TOKEN"
sudo systemctl enable vault
sudo systemctl restart vault
fi
sleep 8
EOF
)"


echo "--> Waiting for Vault leader"
while ! host active.vault.service.consul &> /dev/null; do
  sleep 5
done



if [ ${enterprise} == 0 ]
then
echo "--> OSS - no license necessary"

else
echo "--> Ent - Appyling License"
export VAULT_ADDR="https://active.vault.service.consul:8200"
export VAULT_SKIP_VERIFY=true
export VAULT_TOKEN=$(consul kv get service/vault/root-token)
echo "ROOT TOKEN: $VAULT_TOKEN"
vault write sys/license text=${vaultlicense}
echo "--> Ent - License applied"
fi


echo "--> Attempting to create nomad role"

  echo "--> Adding Nomad policy"
  echo "--> Retrieving root token..."
  export VAULT_ADDR="https://active.vault.service.consul:8200"
  export VAULT_SKIP_VERIFY=true
  consul kv get service/vault/root-token | vault login -

echo "==> Vault is done!"