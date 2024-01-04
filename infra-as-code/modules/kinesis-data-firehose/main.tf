locals {
  RESOURCE_NAME  = "${var.PROJECT_NAME}-${var.ENV}-${var.RESOURCE_SUFFIX}"
  LOG_GROUP_NAME = "/aws/kinesis/firehose/${local.RESOURCE_NAME}"
}

module "security" {
  source          = "./permissions"
  PROJECT_NAME    = var.PROJECT_NAME
  ENV             = var.ENV
  AWS_TAGS        = var.AWS_TAGS
  RESOURCE_SUFFIX = var.RESOURCE_SUFFIX
}

module "observability" {
  source           = "./observability"
  LOG_GROUP_NAME   = local.LOG_GROUP_NAME
  LOG_GROUP_STREAM = var.LOG_STREAM_NAME
  AWS_TAGS         = var.AWS_TAGS
  RESOURCE_NAME    = local.RESOURCE_NAME
}

resource "aws_kinesis_firehose_delivery_stream" "S3_stream" {
  name        = local.RESOURCE_NAME
  destination = var.STREAM_DESTINATION

  extended_s3_configuration {
    bucket_arn          = var.S3_BUCKET_ARN
    role_arn            = module.security.role_arn
    prefix              = var.TIME_FORMAT_PREFIX
    error_output_prefix = var.ERROR_OUTPUT_PREFIX
    buffering_size      = var.BUFFER_SIZE
    buffering_interval  = var.BUFFER_INTERVAL
    compression_format  = var.COMPRESSION_FORMAT_TYPE

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = var.EXTRACTION_QUERY
        }
      }
    }

    dynamic_partitioning_configuration {
      enabled = var.ENABLE_DYNAMIC_PARTITIONING
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = local.LOG_GROUP_NAME
      log_stream_name = var.LOG_STREAM_NAME
    }
  }
  tags = var.AWS_TAGS
}
