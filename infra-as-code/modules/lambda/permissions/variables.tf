variable "RESOURCE_NAME" {}

variable "ECS_TASK_DEFINITIONS_ARN" {
  type = list(string)
}

variable "SECRET_MANAGERS_ARN" {
  type = list(string)
}

variable "ROLES_TO_ASSUME_ARN" {
  type = list(string)
}

variable "FIREHOSE_ARN" {
  type    = string
  default = ""
}



