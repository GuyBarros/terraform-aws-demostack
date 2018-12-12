#!/usr/bin/env bash
set -e

echo "==> Consul Connect Demo Setup"


echo "--> Running MongoDB Nomad Job"
nomad run /demostack/nomad_jobs/nginx-pki.nomad
nomad run /demostack/nomad_jobs/hashibo.nomad
nomad run /demostack/nomad_jobs/orchestrators.nomad


echo "==> Consul Connect Demo Setup is Done!"


