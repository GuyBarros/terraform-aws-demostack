#!/usr/bin/env bash
set -e
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

echo "--> HashiUI"
sudo tee /demostack/hashi-ui.hcl > /dev/null <<"EOF"
job "hashi-ui" {
 region = "global"
  datacenters = ["${region}"]

  type     = "system"
  priority = 75

  task "hashi-ui" {
    driver = "exec"

    config {
      command = "hashi-ui"
    }

    artifact {
      source      = "${hashiui_url}"
      destination = "hashi-ui"
      mode        = "file"
    }

    service {
      port = "http"
      name = "hashi-ui"
      tags = ["urlprefix-/hashi-ui strip=/hashi-ui"]

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    env {
      "NOMAD_ENABLE"      = 1
      "NOMAD_ADDR"        = "https://localhost:4646"
      "NOMAD_CACERT"      = "/usr/local/share/ca-certificates/01-me.crt"
      "NOMAD_CLIENT_CERT" = "/etc/ssl/certs/me.crt"
      "NOMAD_CLIENT_KEY"  = "/etc/ssl/certs/me.key"

      "CONSUL_ENABLE"    = 1
      "CONSUL_ACL_TOKEN" = "anonymous" # Otherwise the UI inherits master
    }

    resources {
      
      network {
        port "http" {
          static = 3000
        }
      }
    }
  }
}
EOF


echo "--> Fabio"
sudo tee /demostack/fabio.hcl > /dev/null <<"EOF"
job "fabio" {
  region = "global"
  datacenters = ["${region}"]

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



if [ ${run_nomad_jobs} == 0 ]
then
echo "--> not running Nomad Jobs"


else
echo "--> Running"
nomad_run /demostack/hashi-ui.hcl
nomad_run /demostack/fabio.hcl
fi

echo "==> Nomad jobs submitted!"
