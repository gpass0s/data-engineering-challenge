locals {
  RESOURCE_NAME = "${var.PROJECT_NAME}-${var.ENV}-lambdaFetcherRole"
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = local.RESOURCE_NAME
  assume_role_policy = data.aws_iam_policy_document.lambda_role.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "lambda_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    effect = "Allow"
    sid    = ""
  }
}

resource "aws_iam_role_policy" "iam_for_lambda_ecs_policy" {
  name   = "${var.PROJECT_NAME}-${var.ENV}-lambdaFetcherPolicy"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.lambda_role_ecs_policy.json
}

data "aws_iam_policy_document" "lambda_role_ecs_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/${var.PROJECT_NAME}-${var.ENV}-fetcher:*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = var.SECRET_MANAGERS_ARN
  }
  statement {
    effect = "Allow"
    actions = [
      "kinesis:PutRecord",
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [
      var.FIREHOSE_ARN
    ]
  }
}