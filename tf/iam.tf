# replace manually setup jenkins-aws credentials
# + add s3 object deletion

data "aws_caller_identity" "current" {}

module "snapshot_user" {
  source = "git::https://github.com/lsst-sqre/terraform-aws-iam-user"
  name   = "${var.env_name}-snap-master-funk"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListingVolumesAndSnapshots",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags"
      ],
      "Resource": [ "*" ]
    },
    {
      "Sid": "AllowSnapshots",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot"
      ],
      "Resource": [ "*" ]
    },
    {
      "Sid": "AllowTagsOnSnapshots",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": [ "arn:aws:ec2:${var.aws_default_region}::snapshot/*" ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction" : "CreateSnapshot",
          "aws:RequestTag/jenkins_env": "${var.env_name}"
        },
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "jenkins_env",
            "Name",
            "PurgeAfterFE",
            "CreatedBy",
            "PurgeAllow"
          ]
        }
      }
    },
    {
      "Sid": "AllowDeleteSnapshotWithTags",
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      "Resource": [ "arn:aws:ec2:${var.aws_default_region}::snapshot/*" ],
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/jenkins_env": "${var.env_name}"
        }
      }
    }
  ]
}
POLICY
}

output "SNAPSHOT_USER" {
  value = "${module.snapshot_user.name}"
}

output "SNAPSHOT_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${module.snapshot_user.id}"
}

output "SNAPSHOT_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${module.snapshot_user.secret}"
}
