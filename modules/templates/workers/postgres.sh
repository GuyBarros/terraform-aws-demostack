#!/usr/bin/env bash
set -e

echo "==> Postgresql"

echo "--> Installing postgresql"
curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
ssh-apt update
ssh-apt install postgresql postgresql-contrib
sudo tee /etc/postgresql/*/main/pg_hba.conf > /dev/null <<"EOF"
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
EOF
sudo systemctl enable postgresql
sudo systemctl restart postgresql

echo "--> Creating database myapp"
psql -U postgres -c 'CREATE DATABASE myapp;' &>/dev/null

echo "--> Setting psql prompt"
sudo tee "/home/${demo_username}/.psqlrc" > /dev/null <<"EOF"
\set QUIET 1
\set COMP_KEYWORD_CASE upper
\set PROMPT1 '%n > '

\echo 'Welcome to PostgreSQL for HashiCorp demo!'
\echo 'Type \\q to exit.\n'
EOF

echo "--> Ensuring .psqlrc is owned by ${demo_username}"
sudo chown "${demo_username}:${demo_username}" "/home/${demo_username}/.psqlrc"

echo "==> Postgresql is done!"
