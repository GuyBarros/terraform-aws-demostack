#!/usr/bin/env bash
set -e

echo "==> Nomad (client)"

echo "--> Fetching"
install_from_url "nomad" "${nomad_url}"

echo "--> Installing"
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

client {
  enabled = true
     options = {
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
  enabled   = true
   address          = "https://active.vault.service.consul:8200"
  ca_file   = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file = "/etc/ssl/certs/me.crt"
  key_file  = "/etc/ssl/certs/me.key"
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

echo "--> Creating workspace"
sudo mkdir -p /workstation/nomad

echo "--> Creating http-echo"
sudo tee /workstation/nomad/http-echo.nomad > /dev/null <<"EOF"
job "http-echo-${node_name}" {
  datacenters = ["dc1"]

  group "echo" {
    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:0.2.3"
        args  = [
          "-listen", ":\$\{NOMAD_PORT_http\}",
          "-text", "hello world",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {
         
          }
        }
      }

      service {
        name = "http-echo"
        port = "http"
        tags = [
          "${node_name}",
          "urlprefix-/http-echo",
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
EOF

echo "--> Changing ownership"
sudo chown -R "${demo_username}:${demo_username}" "/workstation/nomad"

echo "--> Installing completions"
sudo su ${demo_username} \
  -c 'nomad -autocomplete-install'

echo "==> Nomad is done!"
