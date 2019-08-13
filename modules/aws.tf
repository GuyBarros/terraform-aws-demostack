terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "demostack" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_internet_gateway" "demostack" {
  vpc_id = aws_vpc.demostack.id

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.demostack.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.demostack.id
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "demostack" {
  count                   = "${length(var.cidr_blocks)}"
  vpc_id                  = aws_vpc.demostack.id
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block              = "${var.cidr_blocks[count.index]}"
  map_public_ip_on_launch = true

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_security_group" "demostack" {
  name_prefix = var.namespace
  vpc_id      = aws_vpc.demostack.id

#Demostack HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#HTTP 
#TODO - Remove when sslcerts are done
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#Consul and Vault ports
  ingress {
    from_port   = 8000
    to_port     = 8999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#Fabio Ports
  ingress {
    from_port   = 9998
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#Nomad
ingress {
    from_port   = 3000
    to_port     = 4999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
#More nomad ports
  ingress {
    from_port   = 20000
    to_port     = 29999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 39999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "demostack" {
  key_name   = var.namespace
  public_key = var.public_key
}

resource "aws_iam_instance_profile" "consul-join" {
  name = "${var.namespace}-consul-join"
  role = aws_iam_role.consul-join.name
}

resource "aws_kms_key" "demostackVaultKeys" {
  description             = "KMS for the Consul Demo Vault"
  deletion_window_in_days = 10

  tags = {
    Name           = var.namespace
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_iam_policy" "consul-join" {
  name        = "${var.namespace}-consul-join"
  description = "Allows Consul nodes to describe instances for joining."

  policy = data.aws_iam_policy_document.vault-server.json
}


resource "aws_iam_role" "consul-join" {
  name               = "${var.namespace}-consul-join"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}

resource "aws_iam_policy_attachment" "consul-join" {
  name       = "${var.namespace}-consul-join"
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
    ]
      
    resources = ["*"]
  }

  }

resource "aws_route53_record" "hashiui" {
  zone_id = "Z2VGUC188F45PC"
  name    = "${var.namespace}-hashiui"
  type    = "CNAME"
  records = [aws_instance.workers.0.public_dns]
  ttl     = "300"
}
resource "aws_route53_record" "fabio" {
  zone_id = "Z2VGUC188F45PC"
  name    = aws_alb.fabio.name
  type    = "CNAME"
  records = [aws_alb.fabio.dns_name]
  ttl     = "300"
}
resource "aws_route53_record" "consul" {
  zone_id = "Z2VGUC188F45PC"
  name    = aws_alb.consul.name
  type    = "CNAME"
  records = [aws_alb.consul.dns_name]
  ttl     = "300"
}
resource "aws_route53_record" "nomad" {
  zone_id = "Z2VGUC188F45PC"
  name    = aws_alb.nomad.name
  type    = "CNAME"
  records = [aws_alb.nomad.dns_name]
  ttl     = "300"
}
resource "aws_route53_record" "vault" {
  zone_id = "Z2VGUC188F45PC"
  name    = aws_alb.vault.name
  type    = "CNAME"
  records = [aws_alb.vault.dns_name]
  ttl     = "300"
}