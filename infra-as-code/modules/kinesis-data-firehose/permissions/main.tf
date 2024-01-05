data "aws_region" "aws_account_region" {}
data "aws_caller_identity" "aws_account" {}

locals {
  AWS_REGION     = data.aws_region.aws_account_region.name
  AWS_ACCOUNT_ID = data.aws_caller_identity.aws_account.account_id
  RESOURCE_NAME  = "${var.PROJECT_NAME}-${var.ENV}-${var.RESOURCE_SUFFIX}"
}

resource "aws_iam_role" "firehose_iam_role" {
  name               = "${var.PROJECT_NAME}-${var.ENV}-FirehoseAccessRole"
  assume_role_policy = data.aws_iam_policy_document.kinesis_role.json
  path               = "/service-role/"
  tags               = var.AWS_TAGS
}

resource "aws_iam_role_policy" "firehose_iam_policy" {
  name   = "${var.PROJECT_NAME}-${var.ENV}-FirehoseAccessPolicy"
  policy = data.aws_iam_policy_document.kinesis_role_policy.json
  role   = aws_iam_role.firehose_iam_role.id
}

data "aws_iam_policy_document" "kinesis_role" {

  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        "${data.aws_caller_identity.aws_account.account_id}"
      ]

    }
    effect = "Allow"
    sid    = ""
  }
}

data "aws_iam_policy_document" "kinesis_role_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:listBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.PROJECT_NAME}-${var.ENV}-sf-fire-incident/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${local.AWS_REGION}:${local.AWS_ACCOUNT_ID}:log-group:/aws/kinesis/firehose/${local.RESOURCE_NAME}"
    ]
  }
}
