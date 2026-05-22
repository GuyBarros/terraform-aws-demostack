#!/bin/bash
set -ex
exec > >(tee /var/log/userdata.log) 2>&1

echo "==> Bootstrap: starting"

if ! command -v aws &>/dev/null; then
  echo "==> Installing AWS CLI"
  snap install aws-cli --classic || apt-get install -y awscli
fi

%{ for script in scripts ~}
echo "==> Running ${script}"
aws s3 cp "s3://${bucket}/${prefix}/${script}" "/tmp/${script}"
chmod +x "/tmp/${script}"
bash "/tmp/${script}"
%{ endfor ~}

echo "==> Bootstrap: complete"
