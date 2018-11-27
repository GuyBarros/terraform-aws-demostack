#!/usr/bin/env bash
set -e

echo "--> Formatting disk"
sudo mkfs.xfs -K /dev/xvdb
sudo mkdir -p /mnt
sudo mount -o discard /dev/xvdb /mnt
sudo tee -a /etc/fstab > /dev/null <<"EOF"
/dev/xvdb   /mnt   xfs    defaults,nofail,discard   0   2
EOF
