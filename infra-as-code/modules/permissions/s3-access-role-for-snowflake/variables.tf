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

variable "SNOWFLAKE_STORAGE_AWS_EXTERNAL_ID" {}

variable "SNOWFLAKE_STORAGE_AWS_AIM_USER_ARN" {}

variable "S3_BUCKET_NAME" {
  type        = string
  description = "The name of the S# bucket Snowflake will connect to"
}