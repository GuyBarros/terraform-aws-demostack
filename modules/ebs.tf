resource "aws_iam_role" "ebs_volumes" {
  name               = "${var.namespace}-ebs_volumes"
  assume_role_policy = file("${path.module}/templates/policies/assume-role.json")
  tags = local.common_tags
}
resource "aws_iam_role_policy" "mount_ebs_volumes" {
  name   = "mount-ebs-volumes"
  role   = aws_iam_role.ebs_volumes.id
  policy = data.aws_iam_policy_document.mount_ebs_volumes.json
}

data "aws_iam_policy_document" "mount_ebs_volumes" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
    ]
    resources = ["*"]
  }
}


resource "aws_ebs_volume" "mysql" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  size              = 40
  tags = local.common_tags
}

resource "aws_ebs_volume" "mongodb" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  size              = 40
  tags = local.common_tags
}

resource "aws_ebs_volume" "prometheus" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  size              = 40
  tags = local.common_tags
}

resource "aws_ebs_volume" "shared" {
  availability_zone       = data.aws_availability_zones.available.names[0]
  size              = 40
  tags = local.common_tags
}
