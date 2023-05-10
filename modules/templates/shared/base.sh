#!/usr/bin/env bash
set -x

echo "==> Base"

echo "==> libc6 issue workaround"
echo 'libc6 libraries/restart-without-asking boolean true' | sudo debconf-set-selections

function install_from_url {
  cd /tmp && {
    curl -sfLo "$${1}.zip" "$${2}"
    unzip -qq "$${1}.zip"
    sudo mv "$${1}" "/usr/local/bin/$${1}"
    sudo chmod +x "/usr/local/bin/$${1}"
    rm -rf "$${1}.zip"
  }
}



echo "--> Adding helper for IP retrieval"
sudo tee /etc/profile.d/ips.sh > /dev/null <<EOF
function private_ip {
  curl -s http://169.254.169.254/latest/meta-data/local-ipv4
}

function public_ip {
  curl -s http://169.254.169.254/latest/meta-data/public-ipv4
}
EOF
source /etc/profile.d/ips.sh

echo "--> Updating apt-cache"
ssh-apt update

echo "--> Adding trusted root CA"
sudo tee /usr/local/share/ca-certificates/01-me.crt > /dev/null <<EOF
${me_ca}
EOF
sudo update-ca-certificates &>/dev/null

echo "--> Adding my certificates"
sudo tee /etc/ssl/certs/me.crt > /dev/null <<EOF
${me_cert}
EOF
sudo tee /etc/ssl/certs/me.key > /dev/null <<EOF
${me_key}
EOF


echo "--> Setting iptables for bridge networking"
echo 1 > /proc/sys/net/bridge/bridge-nf-call-arptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

echo "--> Making iptables settings for bridge networking config change"
sudo tee /etc/sysctl.d/nomadtables > /dev/null <<EOF
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

echo "--> updated version of Nodejs"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -

echo "--> Adding Hashicorp repo"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
 sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

echo "--> Installing common dependencies"
apt-get install -y \
  build-essential \
  cpu-checker \
  nodejs \
  curl \
  emacs \
  git \
  jq \
  tmux \
  unzip \
  vim \
  wget \
  tree \
  qemu-kvm \
  virt-manager \
  virtinst \
  libvirt-clients \
  bridge-utils \
  libvirt-daemon-system \
  podman \
  nfs-kernel-server \
  nfs-common \
  python3-pip \
  ruby-full \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common \
  openjdk-17-jdk-headless \
  prometheus-node-exporter \
  golang-go \
  alien \
  terraform \
  &>/dev/null


if [ ${enterprise} == 0 ]
then
apt-get install -y \
  vault \
  consul \
  nomad  \
  &>/dev/null

else
apt-get install -y \
vault-enterprise \
  consul-enterprise \
  nomad-enterprise  \
  &>/dev/null

fi

echo "--> Disabling checkpoint"
sudo tee /etc/profile.d/checkpoint.sh > /dev/null <<"EOF"
export CHECKPOINT_DISABLE=1
EOF
source /etc/profile.d/checkpoint.sh

echo "--> Setting hostname..."
echo "${node_name}.node.consul" | sudo tee /etc/hostname
sudo hostname -F /etc/hostname

echo "--> Adding hostname to /etc/hosts"
sudo tee -a /etc/hosts > /dev/null <<EOF

# For local resolution
$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)  ${node_name}.node.consul
EOF


echo "--> Install Envoy"
 curl -L https://getenvoy.io/cli | sudo bash -s -- -b /usr/local/bin
 getenvoy run standard:1.16.0 -- --version
 sudo cp ~/.getenvoy/builds/standard/1.16.0/linux_glibc/bin/envoy /usr/bin/

envoy --version


echo "==> Base is done!"