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

variable "ECS_TASK_DEFINITIONS_ARN" {
  type = list(string)
}

variable "SECRET_MANAGERS_ARN" {
  type = list(string)
}

variable "ROLES_TO_ASSUME_ARN" {
  type = list(string)
}