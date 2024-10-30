#!/usr/bin/env bash
echo "==> Nomad (client)"

echo "==> getting the aws metadata token"
export TOKEN=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

echo "==> check token was set"
echo $TOKEN


echo "--> Installing CNI plugin"
sudo mkdir -p /opt/cni/bin/
export ARCH_CNI=$( [ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)
export CNI_PLUGIN_VERSION=${cni_version}
sudo wget "https://github.com/containernetworking/plugins/releases/download/$${CNI_PLUGIN_VERSION}/cni-plugins-linux-$${ARCH_CNI}-$${CNI_PLUGIN_VERSION}".tgz && \
sudo tar -xzf cni-plugins-linux-$${ARCH_CNI}-v$${CNI_PLUGIN_VERSION}.tgz -C /opt/cni/bin/

export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -fsq http://169.254.169.254/latest/meta-data/placement/availability-zone |  sed 's/[a-z]$//')
export AWS_AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

echo "--> Installing"
sudo mkdir -p /mnt/nomad
sudo mkdir -p /etc/nomad.d/default_jobs

echo "--> clean up any default config."
sudo rm  /etc/nomad.d/*

echo "--> creating directories for host volumes"
sudo mkdir -p /etc/nomad.d/host-volumes/wp-runner
sudo mkdir -p /etc/nomad.d/host-volumes/wp-server


sudo tee /etc/nomad.d/config.hcl > /dev/null <<EOF
name         = "${node_name}"
data_dir     = "/mnt/nomad"
enable_debug = true
bind_addr = "0.0.0.0"

datacenter = "$AWS_AZ"
region = "$AWS_REGION"

/*
advertise {
  http = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4646"
  rpc  = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4647"
  serf = "$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):4648"
}
*/

client {
  enabled = true
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
  tls_skip_verify  = true
  address          = "https://$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4):8200"
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

plugin "qemu" {
  config {
    image_paths = ["/tmp"]
  }
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
ExecStart=/usr/bin/nomad agent -config="/etc/nomad.d"
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
