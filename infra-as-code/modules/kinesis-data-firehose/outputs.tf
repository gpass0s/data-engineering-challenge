output "stream_name" {
  description = "kinesis data stream resource name"
  value       = aws_kinesis_firehose_delivery_stream.S3_stream.name
}
output "arn" {
  description = "kinesis data stream resource arn"
  value       = aws_kinesis_firehose_delivery_stream.S3_stream.arn
}