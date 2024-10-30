#AMI Filter for Windows Server 2019 Base
data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"] # Canonical

}

resource "aws_instance" "windows" {

  ami           = data.aws_ami.windows.id
  instance_type = var.windows_instance_type_worker
  key_name      = aws_key_pair.demostack.id

  subnet_id              = aws_subnet.demostack.0.id
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.demostack.id]


  root_block_device {
    volume_size           = "240"
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size           = "240"
    delete_on_termination = "true"
  }

  tags = merge(local.common_tags ,{
   Purpose        = var.namespace ,
   function       = "Windows"
   Name            = "${var.namespace}-Windows" ,
   }
  )

get_password_data = true
  user_data = base64encode(file("${path.module}/templates/windows/init.ps1"))
}