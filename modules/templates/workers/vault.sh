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
sleep 2



echo "--> Installing completions"
sudo su ${demo_username} \
  -c 'vault -autocomplete-install'

echo "==> Vault is done!"