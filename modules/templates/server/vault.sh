#!/usr/bin/env bash
echo "==> Vault (server)"
# Vault expects the key to be concatenated with the CA
sudo mkdir -p /etc/vault.d/tls/
sudo mkdir -p /etc/vault.d/plugins/
sudo tee /etc/vault.d/tls/vault.crt > /dev/null <<EOF
$(cat /etc/ssl/certs/me.crt)
$(cat /usr/local/share/ca-certificates/01-me.crt)
EOF

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

storage "consul" {
  path = "vault/"
  service = "vault"
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
# api_addr = "https://vault.service.${region}.consul:8200"
# api_addr = "${vault_api_addr}"
plugin_directory = "/etc/vault.d/plugins"
disable_mlock = true
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
consul lock -name=vault-init tmp/vault/lock "$(cat <<"EOF"
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
  path "kv/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

EOR

  vault policy write test - <<EOR
  path "kv/*" {
    capabilities = ["list"]
}

path "kv/test" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/data/test" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "pki/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}


path "kv/metadata/cgtest" {
    capabilities = ["list"]
}


path "kv/data/cgtest" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    control_group = {
        factor "approvers" {
            identity {
                group_names = ["approvers"]
                approvals = 1
            }
        }
    }
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

 echo "--> Mount KV in Vault"
 {
 vault secrets enable -version=2 kv &&
  echo "--> KV Mounted succesfully"
 } ||
 {
   echo "--> KV Already mounted, moving on"
 }

 echo "--> Creating Initial secret for Nomad KV"
  vault kv put kv/test message='Hello world'


 echo "--> nomad nginx-vault-pki demo prep"
{
vault secrets enable pki
 }||
{
  echo "--> pki already enabled, moving on"
}

 {
vault write pki/root/generate/internal common_name=service.consul
}||
{
  echo "--> pki generate internal already configured, moving on"
}
{
vault write pki/roles/consul-service generate_lease=true allowed_domains="service.consul" allow_subdomains="true"
}||
{
  echo "--> pki role already configured, moving on"
}

{
vault policy write superuser - <<EOR
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

path "sys/control-group/authorize" {
    capabilities = ["create", "update"]
}

# To check control group request status
path "sys/control-group/request" {
    capabilities = ["create", "update"]
}

# all access to boundary namespace
path "boundary/*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}


EOR
} ||
{
  echo "--> superuser role already configured, moving on"
}

echo "--> Setting up Github auth"
 {
 vault auth enable github &&
 vault write auth/github/config organization=hashicorp &&
 vault write auth/github/map/teams/team-se  value=default,superuser
  echo "--> github auth done"
 } ||
 {
   echo "--> github auth mounted, moving on"
 }

 echo "--> Setting up vault prepared query"
 {
 curl http://localhost:8500/v1/query \
    --request POST \
    --data \
'{
  "Name": "vault",
  "Service": {
    "Service": "vault",
    "Tags":  ["active"],
    "Failover": {
      "NearestN": 2
    }
  }
}'
  echo "--> consul query done"
 } ||
 {
   echo "-->consul query already done, moving on"
 }


 echo "-->Enabling transform"
vault secrets enable  -path=/data-protection/masking/transform transform

echo "-->Configuring CCN role for transform"
vault write /data-protection/masking/transform/role/ccn transformations=ccn


echo "-->Configuring transformation template"
vault write /data-protection/masking/transform/transformation/ccn \
        type=masking \
        template="card-mask" \
        masking_character="#" \
        allowed_roles=ccn

echo "-->Configuring template masking"
vault write /data-protection/masking/transform/template/card-mask type=regex \
        pattern="(\d{4})-(\d{4})-(\d{4})-\d{4}" \
        alphabet="builtin/numeric"

echo "-->Test transform"
vault write /data-protection/masking/transform/encode/ccn value=2345-2211-3333-4356

echo "-->Boundary setup"
{
vault namespace create boundary
 }||
{
  echo "--> Boundary namespace already created, moving on"
}

echo "-->mount transit in boundary namespace"
{

vault secrets enable  -namespace=boundary -path=transit transit

 }||
{
  echo "--> transit already mounted, moving on"
}

echo "--> creating boundary root key"
{
vault  write -namespace=boundary -f  transit/keys/root
 }||
{
  echo "--> root key already exists, moving on"
}

echo "--> creating boundary worker-auth key"
{
vault write -namespace=boundary  -f  transit/keys/worker-auth

 }||
{
  echo "--> worker-auth key already exists, moving on"
}

# echo "-->Installing Oracle DB plugin"
# ###################################################################################################################
# {
# logger "-->install Oracle dependencies"

# # Install dependencies
# sudo apt install -y alien

# # Download files. Example specific to 19.3
# # Some links were not correct on the downloads page
# # (still pointing to a license page), but easy enough to
# # figure out from working ones
# wget https://download.oracle.com/otn_software/linux/instantclient/193000/oracle-instantclient19.3-basiclite-19.3.0.0.0-1.x86_64.rpm
# wget https://download.oracle.com/otn_software/linux/instantclient/193000/oracle-instantclient19.3-devel-19.3.0.0.0-1.x86_64.rpm
# wget https://download.oracle.com/otn_software/linux/instantclient/193000/oracle-instantclient19.3-sqlplus-19.3.0.0.0-1.x86_64.rpm

# # Install all 3 RPM's downloaded
# sudo alien -i oracle-instantclient19.3-*.rpm

# # Install SQL*Plus dependency
# sudo apt install -y libaio1

# # Create Oracle environment script
# export ORACLE_HOME=/usr/lib/oracle/19.3/client64

# logger "-->Installing Oracle DB plugin"
# sudo wget -P /tmp/ -O vault-plugin-database-oracle_linux_amd64.zip  "${vault_oracle_client_url}"
# sudo unzip -q /tmp/vault-plugin-database-oracle_linux_amd64.zip -d /etc/vault.d/plugins/

# sudo chmod +x /etc/vault.d/plugins/vault-plugin-database-oracle
# shasum -a 256 /etc/vault.d/plugins/vault-plugin-database-oracle > /tmp/oracle-plugin.sha256
# sudo chmod 777 /tmp/oracle-plugin.sha256
# sudo setcap cap_ipc_lock=+ep /etc/vault.d/plugins/vault-plugin-database-oracle

# export VAULT_SKIP_VERIFY=true

# logger "==> Enable Oracle Plugin"
# vault write sys/plugins/catalog/database/vault-plugin-database-oracle \
#     sha256=$(cat /tmp/oracle-plugin.sha256 | head -n1 | awk '{print $1;}') \
#     command="vault-plugin-database-oracle"

#  }
# ############################################################################################################



echo "==> Vault is done!"