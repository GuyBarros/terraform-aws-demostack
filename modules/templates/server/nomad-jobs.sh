#!/usr/bin/env bash
echo "create  demo directory"
sudo mkdir /demostack

echo "==> Nomads jobs"

function nomad_run {
  JOBFILE="$1"
  KEY="tmp/nomad/job/$(sha1sum "$JOBFILE" | awk '{print $1}')"
  consul lock tmp/nomad/job-submitting "$(cat <<EOF
if ! consul kv get "$KEY" &> /dev/null; then
  nomad run "$JOBFILE"
  consul kv put "$KEY"
fi
EOF
)"
}


echo "--> Fabio"
sudo tee /demostack/fabio.hcl > /dev/null <<"EOF"
job "fabio-${region}" {
  datacenters = ["${region}a","${region}b","${region}c"]

  type     = "system"
  priority = 75

  update {
    stagger      = "10s"
    max_parallel = 1
  }

  task "fabio" {
    driver = "exec"

    config {
      command = "fabio"
    }

    artifact {
      source      = "${fabio_url}"
      destination = "fabio"
      mode        = "file"
    }

    service {
      port = "http"
      name = "fabio"

      check {
        type     = "http"
        port     = "ui"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    resources {

      network {

        port "http" {
          static = 9999
        }

        port "ui" {
          static = 9998
        }
      }
    }
  }
}
EOF

echo "--> Running"
# nomad_run /demostack/fabio.hcl

echo "==> Nomad jobs submitted!"
