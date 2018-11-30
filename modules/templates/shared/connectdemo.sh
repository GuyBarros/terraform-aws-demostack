#!/usr/bin/env bash
set -e

echo "==> Consul Connect Demo Setup"


echo "--> Installing common dependencies"
ssh-apt install \
  nodejs \
  npm \
  &>/dev/null
  echo "-->Done installing common dependencies"

echo "--> Installing common npm dependencies"
sudo npm install -g gulp
sudo npm install -g bower
sudo npm install -g nodemon
#sudo npm install -g pm2
echo "--> Done installing common npm dependencies"

echo "create consul demo directory"
sudo mkdir /demostack
echo "Git pull nodejs demo"
 cd /demostack
 sudo git clone https://github.com/GuyBarros/mean_cluster_backend
 cd /demostack/mean_cluster_backend
 echo "install the Nodejs package"
 npm install 


echo "-->  Git pull AngularJs demo"
 cd /demostack
 sudo git clone https://github.com/GuyBarros/mean_cluster
 cd /demostack/mean_cluster
 echo "--> install the Nodejs package"
 sudo npm install 
 echo "--> Bower install"
 sudo bower install --allow-root


echo "-->  Git pull Nomad Jobs"
 cd /demostack
 sudo git clone https://github.com/GuyBarros/nomad_jobs

echo "==> Consul Connect Demo Setup is Done!"


