#!/usr/bin/env bash
set -e

echo "==> Vault (client)"

echo "--> Fetching"
install_from_url "vault" "${vault_url}"



echo "--> Writing profile"
sudo tee /etc/profile.d/vault.sh > /dev/null <<"EOF"
alias v="vault"
alias vualt="vault"
export VAULT_ADDR="http://127.0.0.1:8200"
EOF
source /etc/profile.d/vault.sh

sudo tee /etc/systemd/system/vault.service > /dev/null <<"EOF"
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
Environment=GOMAXPROCS=8
Environment=VAULT_DEV_ROOT_TOKEN_ID=root
Restart=on-failure
ExecStart=/usr/local/bin/vault server -dev
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable vault
sudo systemctl start vault
sleep 2

echo "--> Seeding Vault with a generic secret"
VAULT_TOKEN=root vault kv put secret/training value='Hello!'

echo "--> Creating workspace"
# TODO: Clone https://github.com/hashicorp/demo-vault-beginner.git
# sudo mkdir -p /workstation
# git clone https://github.com/hashicorp/demo-vault-beginner.git /workstation/vault
sudo mkdir -p /workstation/vault

echo "--> Adding files to workstation"
sudo tee /workstation/vault/readonly.sql > /dev/null <<"EOF"
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
EOF

sudo tee /workstation/vault/config.yml.tpl > /dev/null <<"EOF"
---
{{- with secret "database/creds/readonly" }}
username: "{{ .Data.username }}"
password: "{{ .Data.password }}"
database: "myapp"
{{- end }}
EOF

sudo tee /workstation/vault/app.sh > /dev/null <<"EOF"
#!/usr/bin/env bash
cat <<EOT
My connection info is:
  username: "$${DATABASE_CREDS_READONLY_USERNAME}"
  password: "$${DATABASE_CREDS_READONLY_PASSWORD}"
  database: "my-app"
EOT
EOF
sudo chmod +x /workstation/vault/app.sh

echo "--> Generating secondary upstart configuration"
sudo tee /etc/systemd/system/vault-2.service > /dev/null <<"EOF"
[Unit]
Description=Vault Remote
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
ExecStart=/usr/local/bin/vault server -config=/workstation/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo tee /workstation/vault/config.hcl > /dev/null <<"EOF"
# Use the file storage - this will write encrypted data to disk.
storage "file" {
  path = "/workstation/vault/data"
}
# Listen on a different port (8201), which will allow us to run multiple
# Vault's simultaneously.
listener "tcp" {
  address     = "127.0.0.1:8201"
  tls_disable = 1
}
EOF

sudo tee /workstation/vault/base.hcl > /dev/null <<"EOF"
path "secret/data/training_*" {
   capabilities = ["create", "read"]
}
EOF

sudo tee /workstation/vault/data.txt > /dev/null <<"EOF"
{
  "organization": "hashicorp",
  "region": "US-West",
  "zip_code": "94105"
}
EOF

sudo tee /workstation/vault/apps-policy.hcl > /dev/null <<"EOF"
path "secret/data/dev" {
  capabilities = [ "read" ]
}
EOF

sudo tee /workstation/vault/test.hcl > /dev/null <<"EOF"
path "secret/data/test" {
   capabilities = [ "create", "read", "update", "delete" ]
}
EOF

sudo tee /workstation/vault/team-qa.hcl > /dev/null <<"EOF"
path "secret/data/team/qa" {
   capabilities = [ "create", "read", "update", "delete" ]
}
EOF

sudo tee /workstation/vault/team-eng.hcl > /dev/null <<"EOF"
path "secret/data/team/eng" {
   capabilities = [ "create", "read", "update", "delete" ]
}
EOF

sudo tee /workstation/vault/db_creds.hcl > /dev/null <<"EOF"
# Get credentials from the database backend
path "database/creds/readonly" {
  capabilities = [ "read" ]
}
# Renew the lease
path "/sys/leases/renew" {
  capabilities = [ "update" ]
}
EOF


echo "--> Changing ownership"
sudo chown -R "${demo_username}:${demo_username}" "/workstation/vault"

echo "--> Installing completions"
sudo su ${demo_username} \
  -c 'vault -autocomplete-install'

echo "==> Vault is done!"