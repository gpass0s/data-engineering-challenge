module "landing-bucket" {
  source                        = "./modules/s3"
  ENV                           = local.ENV
  PROJECT_NAME                  = local.PROJECT_NAME
  AWS_TAGS                      = local.AWS_TAGS
  RESOURCE_SUFFIX               = "sf-fire-incident"
  CREATE_S3_NOTIFICATION_TOPIC  = true
  S3_NOTIFICATION_QUEUE_ARN     = var.SNOWFLAKE_INTEGRATION_NOTIFICATION_CHANNEL_ARN
  S3_NOTIFICATION_FILTER_PREFIX = "incidents/"
  ENABLE_ARCHIVING              = "Enabled"
  ARCHIVING_SETTINGS = {
    "prefix"                  = ""
    "archiving_storage_class" = "GLACIER_IR"
    "archiving_days"          = 180
  }
  ENABLE_TRANSITION_TO_INFREQUENT_ZONE = "Enabled"
  TRANSITION_TO_INFREQUENT_ZONE_SETTINGS = {
    "prefix"                          = "/"
    "first_transition_storage_class"  = "STANDARD_IA"
    "first_transition_days"           = 30
    "second_transition_storage_class" = "ONEZONE_IA"
    "second_transition_days"          = 90
  }
}