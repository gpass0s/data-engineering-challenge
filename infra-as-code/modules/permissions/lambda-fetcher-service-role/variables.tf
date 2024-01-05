# Variables section

variable "PROJECT_NAME" {
  description = "The name of the project"
}

variable "ENV" {
  description = "The environment (e.g., dev, prod)"
}

variable "AWS_TAGS" {
  description = <<EOF
  Tags are key-value pairs that provide metadata and labeling to resources for
better management.
EOF
  type        = map(string)
}

variable "SECRET_MANAGERS_ARN" {}

variable "FIREHOSE_ARN" {}