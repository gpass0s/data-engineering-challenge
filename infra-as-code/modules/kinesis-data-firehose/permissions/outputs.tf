output "role_arn" {
  value       = aws_iam_role.firehose_iam_role.arn
  description = "The firehose iam role"
}