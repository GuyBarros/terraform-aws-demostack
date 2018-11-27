#!/usr/bin/env bash
set -e

echo "==> Terraform"

echo "--> Fetching"
install_from_url "terraform" "${terraform_url}"

echo "--> Writing profile"
sudo tee /etc/profile.d/terraform.sh > /dev/null <<"EOF"
alias tf="terraform"
EOF

echo "--> Creating workspace"
sudo mkdir -p /workstation
git clone https://github.com/hashicorp/demo-terraform-101.git /workstation/terraform
git clone https://github.com/hashicorp/demo-terraform-201.git /workstation/terraform-201

echo "--> Installing fallback credentials"
sudo tee ~/.metadata > /dev/null <<"EOF"
ami                = "${ami_id}"
region             = "${region}"
identity           = "${identity}"
access_key         = "${access_key}"
secret_key         = "${secret_key}"
subnet_id          = "${subnet_id}"
vpc_security_group_id  = "${security_group_id}"
EOF

echo "--> Enabling git-secrets"
cd /workstation/terraform
git secrets --install
git secrets --register-aws
cd -

echo "--> Adding main.tf"
sudo tee /workstation/terraform/main.tf > /dev/null <<"EOF"
#
# DO NOT DELETE THESE LINES UNTIL INSTRUCTED TO!
#
# Your AMI ID is:
#
#     ${ami_id}
#
# Your subnet ID is:
#
#     ${subnet_id}
#
# Your VPC security group ID is:
#
#     ${security_group_id}
#
# Your Identity is:
#
#     ${identity}
#

provider "aws" {
  access_key = "${access_key}"
  secret_key = "${secret_key}"
  region     = "${region}"
}

resource "aws_instance" "web" {
  # ...
}
EOF

echo "--> Adding commented tfvars"
sudo tee /workstation/terraform/terraform.tfvars > /dev/null <<"EOF"
# access_key        = "${access_key}"
# secret_key        = "${secret_key}"
# ami               = "${ami_id}"
# subnet_id         = "${subnet_id}"
# identity          = "${identity}"
# region            = "${region}"
# vpc_security_group_id = "${security_group_id}"
EOF

echo "--> Adding env vars"
mkdir -p "/home/${demo_username}/.config/envs"
sudo tee "/home/${demo_username}/.config/envs/aws" > /dev/null <<"EOF"
export AWS_ACCESS_KEY_ID="${access_key}"
export AWS_SECRET_ACCESS_KEY="${secret_key}"
export AWS_DEFAULT_REGION="${region}"
EOF

echo "--> Changing ownership"
sudo chown -R "${demo_username}:${demo_username}" "/workstation/terraform"
sudo chown -R "${demo_username}:${demo_username}" "/workstation/terraform-201"
sudo chown -R "${demo_username}:${demo_username}" "/home/${demo_username}/.config"

echo "==> Terraform is done!"
