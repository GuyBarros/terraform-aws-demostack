
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
