locals {
  RESOURCE_NAME = "${var.PROJECT_NAME}-${var.ENV}-s3AccessRoleForSnowflake"
}

resource "aws_iam_role" "snowflake_external_access_iam_role" {
  name = local.RESOURCE_NAME
  path = "/service-role/"
  tags = var.AWS_TAGS

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${var.SNOWFLAKE_STORAGE_AWS_AIM_USER_ARN}"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
              "StringEquals":{
                "sts:ExternalId": "${var.SNOWFLAKE_STORAGE_AWS_EXTERNAL_ID}"
              }
            }
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "snowflake_external_access_iam_policy" {
  name = local.RESOURCE_NAME
  role = aws_iam_role.snowflake_external_access_iam_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "s3:GetObject",
              "s3:GetObjectVersion"
            ],
            "Resource": [
              "arn:aws:s3:::${var.S3_BUCKET_NAME}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::${var.S3_BUCKET_NAME}",
            "Condition": {
                "StringLike": {
                    "s3:prefix": [
                        "/*"
                    ]
                }
            }
        }
    ]
}
EOF
}