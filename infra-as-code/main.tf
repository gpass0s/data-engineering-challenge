data "aws_region" "current_region" {}
data "aws_caller_identity" "current" {}

locals {
  PROJECT_NAME   = "data-engineering-challenge"
  ENV            = terraform.workspace
  AWS_REGION     = data.aws_region.current_region.name
  AWS_TAGS       = merge(var.AWS_TAGS, tomap({ "Environment" = terraform.workspace }))
  AWS_ACCOUNT_ID = data.aws_caller_identity.current.account_id
}

#These resources are defined manually in the AWS account
data "aws_secretsmanager_secret" "snowflake-dbt-credentials" {
  name = "gpassos/${local.ENV}/snowflake/dbt"
}

data "aws_secretsmanager_secret" "socrata-api-key" {
  name = "gpassos/${local.ENV}/socrata/orchestrator/keys"
}

module "firehose-ingestion" {
  source                      = "./modules/kinesis-data-firehose"
  ENV                         = local.ENV
  PROJECT_NAME                = local.PROJECT_NAME
  RESOURCE_SUFFIX             = "delivery-stream"
  LOG_STREAM_NAME             = "delivery-stream"
  S3_BUCKET_ARN               = module.landing-bucket.arn
  STREAM_DESTINATION          = "extended_s3"
  TIME_FORMAT_PREFIX          = "incidents/station_area=!{partitionKeyFromQuery:stationArea}/"
  ERROR_OUTPUT_PREFIX         = "firehose-errors/!{firehose:error-output-type}/dt=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/hour=!{timestamp:HH}/"
  BUFFER_SIZE                 = 128
  BUFFER_INTERVAL             = 60
  ENABLE_DYNAMIC_PARTITIONING = true
  EXTRACTION_QUERY            = "{stationArea:.station_area}"
  AWS_TAGS                    = local.AWS_TAGS
}

module "lambda-layer" {
  source              = "./modules/lambda-layer"
  ENV                 = local.ENV
  PROJECT_NAME        = local.PROJECT_NAME
  RESOURCE_SUFFIX     = "lambda-layer"
  BUILDER_SCRIPT_PATH = "../utils/lambda_layer_builder.sh"
  REQUIREMENTS_PATH   = "requirements.txt"
  PACKAGE_OUTPUT_NAME = "lambda-layer"
  PYTHON_RUNTIME      = "python3.9"
}

module "lambda-orchestrator" {
  source          = "./modules/lambda"
  ENV             = local.ENV
  PROJECT_NAME    = local.PROJECT_NAME
  LAMBDA_LAYER    = [module.lambda-layer.arn]
  RESOURCE_SUFFIX = "orchestrator"
  LAMBDA_SETTINGS = {
    "description"        = "This fetches data from Socrata and starts a ECS task on fargate that runs dbt"
    "handler"            = "orchestrator.lambda_handler"
    "runtime"            = "python3.9"
    "timeout"            = 450
    "memory_size"        = 2048
    "lambda_script_path" = "../lambda-code/orchestrator.py"
  }
  ROLES_TO_ASSUME_ARN = [
    module.ecs-task-definition.dbt-fargate-task-role-arn,
    module.ecs-task-definition.task-definition-role-arn
  ]
  ECS_TASK_DEFINITIONS_ARN = [
    module.ecs-task-definition.task-definition-arn
  ]
  SECRET_MANAGERS_ARN = [
    data.aws_secretsmanager_secret.socrata-api-key.arn,
    data.aws_secretsmanager_secret.snowflake-dbt-credentials.arn
  ]
  FIREHOSE_ARN = module.firehose-ingestion.arn

  LAMBDA_ENVIRONMENT_VARIABLES = {
    ECS_CLUSTER_NAME              = module.ecs-cluster-for-dbt.cluster_name
    ECS_TASK_DEFINITION_ARN       = module.ecs-task-definition.task-definition-arn
    ECS_TASK_SUBNET_ID            = "module.private_subnet_1a.id"
    ECS_SECURITY_GROUP_ID         = "module.ecs-resources-security-group.id"
    SNOWFLAKE_SECRET_MANAGER_NAME = data.aws_secretsmanager_secret.snowflake-dbt-credentials.id
    API_KEYS_SECRET_MANAGER_NAME  = data.aws_secretsmanager_secret.socrata-api-key.id
    FIREHOSE_STREAM_NAME          = module.firehose-ingestion.stream_name
    CONTAINER_NAME                = module.ecs-task-definition.task-definition-container-name
    ENVIRONMENT                   = local.ENV
  }
  CREATE_INVOKER_TRIGGER = true
  LAMBDA_EXECUTION_FREQUENCY = {
    dev = {
      rate  = "99999999"
      unity = "minutes"
    }
    qa = {
      rate  = "5"
      unity = "minutes"
    }
    stg = {
      rate  = "5"
      unity = "minutes"
    }
    prd = {
      rate  = "5"
      unity = "minutes"
    }
  }
  AWS_TAGS = local.AWS_TAGS
}

module "s3-access-role-for-snowflake" {
  source                             = "./modules/permissions/s3-access-role-for-snowflake"
  PROJECT_NAME                       = local.PROJECT_NAME
  ENV                                = local.ENV
  AWS_TAGS                           = local.AWS_TAGS
  SNOWFLAKE_STORAGE_AWS_AIM_USER_ARN = var.SNOWFLAKE_STORAGE_AWS_AIM_USER_ARN
  SNOWFLAKE_STORAGE_AWS_EXTERNAL_ID  = var.SNOWFLAKE_STORAGE_AWS_EXTERNAL_IDS[local.ENV]
  S3_BUCKET_NAME                     = module.landing-bucket.id
}