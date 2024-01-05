variable "LOG_GROUP_NAME" {}

variable "LOG_GROUP_STREAM" {}

variable "AWS_TAGS" {
  description = <<EOF
  Tags are key-value pairs that provide metadata and labeling to resources for
better management.
EOF
  type        = map(string)
}

variable "RESOURCE_NAME" {}
