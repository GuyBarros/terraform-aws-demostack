#!/usr/bin/env bash
set -e

echo "==> Run Nomad Jobs"



echo "create  demo directory"
sudo mkdir /demostack

echo "-->  Git pull Nomad Jobs"
 cd /demostack
 sudo git clone https://github.com/GuyBarros/nomad_jobs


if [ ${run_nomad_jobs} == 0 ]
then
echo "--> not running Nomad Jobs"



else



echo "--> Waiting for Vault leader"
while ! host active.vault.service.consul &> /dev/null; do
  sleep 5
done


echo "--> Waiting for Nomad leader"
while [ -z "$(curl -s http://localhost:4646/v1/status/leader)" ]; do
  sleep 5
done

sleep 180


echo "--> Running  Nomad Job"

 nomad run /demostack/nomad_jobs/hashibo.nomad
 nomad run /demostack/nomad_jobs/catalogue-with-connect.nomad
 nomad run /demostack/nomad_jobs/nginx-pki.nomad

fi

 

echo "==> Run Nomad is Done!"


