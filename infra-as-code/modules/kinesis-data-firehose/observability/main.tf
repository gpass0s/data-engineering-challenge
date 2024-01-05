resource "aws_cloudwatch_log_group" "firehose_cloudwatch_log_group" {
  name              = var.LOG_GROUP_NAME
  retention_in_days = 30
  tags              = var.AWS_TAGS
}

resource "aws_cloudwatch_log_stream" "firehose_cloudwatch_log_stream" {
  name           = var.LOG_GROUP_STREAM
  log_group_name = aws_cloudwatch_log_group.firehose_cloudwatch_log_group.name
}





