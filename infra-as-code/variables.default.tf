variable "AWS_TAGS" {
  type = map(string)
  default = {
    "Project Name"        = "data-engineering-challenge"
    "Project Description" = "Data "
    "Sector"              = "A random data engineering challenge to evaluate my proficiency in Data Engineering"
    "Company"             = "Passos Data Engineering"
    "Cost center"         = "0002"
  }
}

variable "VPC_CIDR_BLOCKS" {
  type = map(string)
  default = {
    dev = "192.168.0.0/16"
    stg = "192.168.0.0/16"
    prd = "192.168.0.0/16"
  }
}

variable "PRIVATE_SUBNET_1A_CIDR_BLOCKS" {
  type = map(string)
  default = {
    dev = "192.168.0.0/24"
    qa  = "11.0.0.0/24"
    stg = "192.168.0.0/24"
    prd = "192.168.0.0/24"
  }
}

variable "PUBLIC_SUBNET_1A_CIDR_BLOCKS" {
  type = map(string)
  default = {
    dev = "192.168.3.0/24"
    qa  = "11.0.3.0/24"
    stg = "192.168.3.0/24"
    prd = "192.168.3.0/24"
  }
}

variable "SNOWFLAKE_STORAGE_AWS_EXTERNAL_IDS" {
  type = map(string)
  default = {
    dev = "XCB75608_SFCRole=2_u26wx6lPBrz/nLvCXjzRBv4LQaA="
    qa  = ""
    stg = ""
    prd = ""
  }
}

variable "SNOWFLAKE_STORAGE_AWS_AIM_USER_ARN" {
  type    = string
  default = "arn:aws:iam::373601657131:user/hlug0000-s"
}

variable "SNOWFLAKE_INTEGRATION_NOTIFICATION_CHANNEL_ARN" {
  default = "arn:aws:sqs:us-east-1:373601657131:sf-snowpipe-AIDAVN7DE4EV43BVZWGS7-nX-5dPwspsRFMjMpzF54yg"
}