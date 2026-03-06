terraform {
  required_version = ">= 0.11.0"
}


//Getting the Domaing name
data "aws_route53_zone" "fdqn" {
  zone_id = var.zone_id
}


#  data "aws_ami" "ubuntu" {
#    most_recent = true
#    filter {
#      name = "name"
#      # values = ["ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"]
#      values = ["ubuntu/images/*ubuntu-jammy-22.04-arm64-server-*"]
#    }

#    filter {
#      name   = "virtualization-type"
#      values = ["hvm"]
#    }

#    owners = ["099720109477"] # Canonical
#  }

 data "aws_ami" "ubuntu" {
 # for_each = toset(["amd64", "arm64"])

  filter {
    name   = "name"
    values = [format("hc-base-ubuntu-2404-%s-*", "arm64")]
    # values = [format("hc-base-ubuntu-2404-%s-*", each.value)]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  most_recent = true
  owners      = ["888995627335"] # hc-ami_prod
}

resource "aws_vpc" "demostack" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags

}

resource "aws_internet_gateway" "demostack" {
  vpc_id = aws_vpc.demostack.id

  tags = local.common_tags
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.demostack.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demostack.id

}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "demostack" {
  count                   = length(var.cidr_blocks)
  vpc_id                  = aws_vpc.demostack.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.cidr_blocks[count.index]
  map_public_ip_on_launch = true

  tags = local.common_tags
}




resource "aws_key_pair" "demostack" {
  key_name   = var.namespace
  public_key = var.public_key

  tags = local.common_tags
}

resource "aws_iam_instance_profile" "consul-join" {
  name = "${var.namespace}-consul-join-instance-profile"
  role = aws_iam_role.consul-join.name
tags = local.common_tags

}

resource "aws_kms_key" "demostackVaultKeys" {
  description             = "KMS for the Consul Demo Vault"
  deletion_window_in_days = 10

   tags = local.common_tags
}

resource "aws_iam_policy" "consul-join" {
  name        = "${var.namespace}-consul-join-iam-policy"
  description = "Allows Consul nodes to describe instances for joining."

  policy = data.aws_iam_policy_document.vault-server.json

tags = local.common_tags
}


resource "aws_iam_role" "consul-join" {
  name               = "${var.namespace}-consul-join-role"
  assume_role_policy = file("${path.module}/templates/policies/assume-role.json")

  tags = local.common_tags
}

resource "aws_iam_policy_attachment" "consul-join" {
  name       = "${var.namespace}-consul-join-policy-attach"
  roles      = [aws_iam_role.consul-join.name]
  policy_arn = aws_iam_policy.consul-join.arn

}


data "aws_iam_policy_document" "vault-server" {
  statement {
    sid    = "VaultKMSUnseal"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.demostackVaultKeys.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "iam:PassRole",
      "iam:ListRoles",
      "cloudwatch:PutMetricData",
      "ds:DescribeDirectories",
      "ec2:DescribeInstanceStatus",
      "logs:*",
      "ec2messages:*",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }

}
