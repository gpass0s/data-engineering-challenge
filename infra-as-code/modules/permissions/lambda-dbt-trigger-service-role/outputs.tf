output "arn" {
  value       = aws_iam_role.iam_for_lambda.arn
  description = "Lambda IAM Role ARN"
}

output "name" {
  value       = aws_iam_role.iam_for_lambda.name
  description = "Lambda IAM Role ARN"
}