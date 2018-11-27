terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
  version = ">= 1.20.0"
  region  = "${var.region}"
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

resource "aws_vpc" "consuldemo" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_hostnames = true

  tags {
    Name           = "${var.namespace}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}

resource "aws_internet_gateway" "consuldemo" {
  vpc_id = "${aws_vpc.consuldemo.id}"

  tags {
    Name           = "${var.namespace}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.consuldemo.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.consuldemo.id}"
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "consuldemo" {
  count                   = "${length(var.cidr_blocks)}"
  vpc_id                  = "${aws_vpc.consuldemo.id}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block              = "${var.cidr_blocks[count.index]}"
  map_public_ip_on_launch = true

  tags {
    Name           = "${var.namespace}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}

resource "aws_security_group" "consuldemo" {
  name_prefix = "${var.namespace}"
  vpc_id      = "${aws_vpc.consuldemo.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "consuldemo" {
  key_name   = "${var.namespace}"
  public_key = "${var.public_key}"
}

resource "aws_iam_role" "consul-join" {
  name               = "${var.namespace}-consul-join"
  assume_role_policy = "${file("${path.module}/templates/policies/assume-role.json")}"
}



resource "aws_iam_policy_attachment" "consul-join" {
  name       = "${var.namespace}-consul-join"
  roles      = ["${aws_iam_role.consul-join.name}"]
  policy_arn = "${aws_iam_policy.consul-join.arn}"
}

resource "aws_iam_instance_profile" "consul-join" {
  name = "${var.namespace}-consul-join"
  role = "${aws_iam_role.consul-join.name}"
}

resource "aws_kms_key" "consulDemoVaultKeys" {
  description             = "KMS for the Consul Demo Vault"
  deletion_window_in_days = 10

  tags {
    Name           = "${var.namespace}"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}

resource "aws_iam_policy" "consul-join" {
  name        = "${var.namespace}-consul-join"
  description = "Allows Consul nodes to describe instances for joining."
 # policy      = "${file("${path.module}/templates/policies/describe-instances.json")}"
 policy = "${data.aws_iam_policy_document.vault-server.json}"
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
   resources = ["${aws_kms_key.consulDemoVaultKeys.arn}"]
  }
   statement 
    {
      effect = "Allow",
     actions = [ "ec2:DescribeInstances",]
      resources = [ "*" ]
    }
}