#!/usr/bin/env bash 
set -ex

echo "==> Vault (server)"
# Vault expects the key to be concatenated with the CA
sudo mkdir -p /etc/vault.d/tls/
sudo tee /etc/vault.d/tls/vault.crt > /dev/null <<EOF
$(cat /etc/ssl/certs/me.crt)
$(cat /usr/local/share/ca-certificates/01-me.crt)
EOF

echo "==> checking if we are using enterprise binaries"
echo "==> value of enterprise is ${enterprise}"

if [ ${enterprise} == 0 ]
then
echo "--> Fetching"
install_from_url "vault" "${vault_url}"

echo "--> Writing configuration"
sudo mkdir -p /etc/vault.d
sudo tee /etc/vault.d/config.hcl > /dev/null <<EOF


cluster_name = "${namespace}-demostack"

storage "consul" {
  path = "vault/"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/etc/vault.d/tls/vault.crt"
  tls_key_file  = "/etc/ssl/certs/me.key"
}

api_addr = "https://$(public_ip):8200"



ui = true

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
  curl \
    --silent \
    --insecure \
    --request PUT \
    --data '{"secret_shares": 1, "secret_threshold": 1}' \
    https://127.0.0.1:8200/v1/sys/init > /tmp/init

  cat /tmp/init | tr '\n' ' ' | jq -r .keys[0] | consul kv put service/vault/unseal-key -
  cat /tmp/init | tr '\n' ' ' | jq -r .root_token | consul kv put service/vault/root-token -

  # shred /tmp/unseal-key /tmp/init
fi
sleep 2
EOF
)"

echo "--> Installing unseal helper"
sudo tee /usr/local/bin/vault-unseal > /dev/null <<"EOF"
#!/usr/bin/env bash
set -e

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true

echo "Reading unseal key from KV"
OUTPUT="$(consul kv get service/vault/unseal-key)"
if [ -z "$OUTPUT" ]; then
  echo "No unseal key found!"
  exit 1
fi

echo "Unsealing Vault"
KEY="$(consul kv get service/vault/unseal-key)"
vault operator unseal "$KEY" &> /dev/null

echo "Vault is unsealed!"
EOF
sudo chmod +x /usr/local/bin/vault-unseal

echo "--> Generating auto-unseal configuration"
sudo tee /etc/systemd/system/vault-unseal.service > /dev/null <<"EOF"
[Unit]
Description=Vault Unseal
Requires=vault.service
After=vault.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vault-unseal

[Install]
WantedBy=multi-user.target
EOF

echo "--> Unsealing"
sudo systemctl enable vault-unseal
sudo systemctl start vault-unseal

echo "--> Waiting for Vault leader"
while ! host active.vault.service.consul &> /dev/null; do
  sleep 5
done

else
echo "--> Fetching"
install_from_url "vault" "${vault_ent_url}"

echo "--> Writing configuration"
sudo mkdir -p /etc/vault.d
sudo tee /etc/vault.d/config.hcl > /dev/null <<EOF

cluster_name = "${namespace}-demostack"

storage "consul" {
  path = "vault/"
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

api_addr = "https://$(public_ip):8200"

ui = true

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
  vault operator init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 > /tmp/out.txt


  cat /tmp/out.txt | grep "Recovery Key 1" | sed 's/Recovery Key 1: //' | consul kv put service/vault/recovery-key -
   cat /tmp/out.txt | grep "Initial Root Token" | sed 's/Initial Root Token: //' | consul kv put service/vault/root-token -
  
export VAULT_TOKEN=$(consul kv get service/vault/root-token)
echo "ROOT TOKEN: $VAULT_TOKEN"
vault write sys/license text=${vaultlicense}
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



fi




echo "--> Attempting to create nomad role"

  echo "--> Adding Nomad policy"
  echo "--> Retrieving root token..."
  export VAULT_ADDR="https://active.vault.service.consul:8200"
  export VAULT_SKIP_VERIFY=true
  consul kv get service/vault/root-token | vault login -

  vault policy write nomad-server - <<EOR
  path "auth/token/create/nomad-cluster" {
    capabilities = ["update"]
  }

  path "auth/token/revoke-accessor" {
    capabilities = ["update"]
  }

  path "auth/token/roles/nomad-cluster" {
    capabilities = ["read"]
  }

  path "auth/token/lookup-self" {
    capabilities = ["read"]
  }

  path "auth/token/lookup" {
    capabilities = ["update"]
  }

  path "auth/token/revoke-accessor" {
    capabilities = ["update"]
  }

  path "sys/capabilities-self" {
    capabilities = ["update"]
  }

  path "auth/token/renew-self" {
    capabilities = ["update"]
  }
EOR

  vault policy write test - <<EOR
  path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOR


  echo "--> Creating Nomad token role"
  vault write auth/token/roles/nomad-cluster \
    name=nomad-cluster \
    period=259200 \
    renewable=true \
    orphan=false \
    disallowed_policies=nomad-server \
    explicit_max_ttl=0
 
 echo "--> Creating Initial secret for Nomad KV"
 vault write secret/test message='Hello world'

 echo "--> nomad nginx-vault-pki demo prep"
{
vault secrets enable pki &&

vault write pki/root/generate/internal common_name=service.consul &&

vault write pki/roles/consul-service generate_lease=true allowed_domains="service.consul" allow_subdomains="true"  &&

vault write pki/issue/consul-service  common_name=nginx.service.consul  ttl=720h  &&

vault policy-write superuser - <<EOR
path "*" { 
  capabilities = ["create", "read", "update", "delete", "list", "sudo"] 
  }

EOR
  
} ||
{
  echo "--> pki demo already configured, moving on"
}
 
echo "==> Vault is done!"
