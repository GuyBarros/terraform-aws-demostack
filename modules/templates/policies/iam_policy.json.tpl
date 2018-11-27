{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*SSHPublicKey*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Sid": "AllowKeyPairAccess",
      "Action": [
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair",
        "ec2:DescribeKeyPairs",
        "ec2:ImportKeyPair"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "AllowBasicAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ec2:CreateTags",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances"
      ],
      "Sid": "RestrictInstanceTypes",
      "Resource": [
        "arn:aws:ec2:${region}:${owner_id}:instance/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:InstanceType": [
            "t2.nano",
            "t2.micro",
            "t2.small",
            "t2.medium"
          ]
        }
      }
    },
    {
      "Sid": "AllowModifyNetworkInterface",
      "Effect": "Allow",
      "Action": [
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "ec2:SourceDestCheck": true
        }
      }
    },
    {
      "Sid": "RestrictInstanceLocation",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${region}::image/${ami_id}",
        "arn:aws:ec2:${region}:${owner_id}:subnet/${subnet_id}",
        "arn:aws:ec2:${region}:${owner_id}:network-interface/*",
        "arn:aws:ec2:${region}:${owner_id}:volume/*",
        "arn:aws:ec2:${region}:${owner_id}:key-pair/*",
        "arn:aws:ec2:${region}:${owner_id}:security-group/${security_group_id}"
      ]
    },
    {
      "Sid": "RestrictInstanceLifecycle",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": [
        "arn:aws:ec2:${region}:${owner_id}:instance/*"
      ]
    }
  ]
}
