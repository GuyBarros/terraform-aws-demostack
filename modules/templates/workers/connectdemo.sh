#!/usr/bin/env bash
set -e

echo "==> Consul Connect Demo Setup"


echo "--> Running MongoDB Nomad Job"

nomad run /demostack/nomad_jobs/mongodb.nomad

echo "==> Consul Connect Demo Setup is Done!"


