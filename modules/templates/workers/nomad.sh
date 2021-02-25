#!/usr/bin/env bash
echo "==> Nomad (client)"

echo "--> Fetching"
echo "==> Nomad (server)"
if [ ${enterprise} == 0 ]
then
echo "--> Fetching OSS binaries"
install_from_url "nomad" "${nomad_url}"
else
echo "--> Fetching enterprise binaries"
install_from_url "nomad" "${nomad_ent_url}"
fi


echo "--> Installing CNI plugin"
sudo mkdir -p /opt/cni/bin/
wget -O cni.tgz ${cni_plugin_url}
sudo tar -xzf cni.tgz -C /opt/cni/bin/

export AWS_REGION=$(curl -fsq http://169.254.169.254/latest/meta-data/placement/availability-zone |  sed 's/[a-z]$//')
export AWS_AZ=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)

echo "--> Installing"
sudo mkdir -p /mnt/nomad
sudo mkdir -p /etc/nomad.d/default_jobs
sudo tee /etc/nomad.d/config.hcl > /dev/null <<EOF
name         = "${node_name}"
data_dir     = "/mnt/nomad"
enable_debug = true
bind_addr = "0.0.0.0"

datacenter = "$AWS_AZ"
region = "$AWS_REGION"

advertise {
  http = "$(public_ip):4646"
  rpc  = "$(public_ip):4647"
  serf = "$(public_ip):4648"
}
client {
  enabled = true
   options {
    "driver.raw_exec.enable" = "1"
     "docker.privileged.enabled" = "true"
  }
  meta {
    "type" = "worker",
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

echo "--> Generating upstart configuration"
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

echo "--> Starting nomad"
sudo systemctl enable nomad
sudo systemctl start nomad

echo "==> Run Nomad is Done!"
