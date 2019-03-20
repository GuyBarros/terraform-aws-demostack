#!/usr/bin/env bash
set -e

echo "==> Run Nomad Jobs"
echo "create  demo directory"
sudo mkdir /demostack

echo "-->  Git pull Nomad Jobs"
 cd /demostack
 sudo git clone https://github.com/GuyBarros/nomad_jobs


echo "--> Running  Nomad Job"
nomad run /demostack/nomad_jobs/nginx-pki.nomad
nomad run /demostack/nomad_jobs/hashibo.nomad
nomad run /demostack/nomad_jobs/orchestrators.nomad
nomad run /demostack/nomad_jobs/catalogue-with-connect.nomad

echo "==> Run Nomad is Done!"


