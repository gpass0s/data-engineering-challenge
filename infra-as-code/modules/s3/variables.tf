variable "ENV" {}

variable "PROJECT_NAME" {}

variable "RESOURCE_SUFFIX" {}

variable "ENABLE_VERSIONING" {
  default = "Suspended"
}

variable "ENABLE_EXPIRES_VERSIONED_OBJECTS" {
  default = "Disabled"
}

variable "ENABLE_ARCHIVING" {
  default = "Disabled"
}

variable "ARCHIVING_SETTINGS" {
  type = any

  default = {
    "prefix"                  = "/"
    "archiving_storage_class" = "GLACIER_IR"
    "archiving_days"          = 365
  }
}

variable "ENABLE_TRANSITION_TO_INFREQUENT_ZONE" {
  default = "Disabled"
}

variable "TRANSITION_TO_INFREQUENT_ZONE_SETTINGS" {
  type = any
  default = {
    "prefix"                          = "/"
    "first_transition_storage_class"  = "STANDARD_IA"
    "first_transition_days"           = 30
    "second_transition_storage_class" = "ONEZONE_IA"
    "second_transition_days"          = 90
  }
}



variable "S3_NOTIFICATION_QUEUE_ARN" {
  default = ""
}

variable "CREATE_S3_NOTIFICATION_TOPIC" {
  default = false
}

variable "S3_NOTIFICATION_FILTER_PREFIX" {
  default = ""
}

variable "CREATE_BUCKET_POLICY" {
  default = false
}

variable "AWS_TAGS" { type = map(string) }

variable "BUCKET_POLICY_DOCUMENT" {
  default = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::111122223333:root"
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::buket-name",
                "arn:aws:s3:::bucket-name/*"
            ]
        }
    ]
}
EOF
}

variable "DAYS_TO_EXPIRE_VERSIONED_OBJECTS" {
  default = 365
}

variable "S3_NOTIFICATION_EVENT_LIST" {
  type    = list(string)
  default = ["s3:ObjectCreated:*"]
}