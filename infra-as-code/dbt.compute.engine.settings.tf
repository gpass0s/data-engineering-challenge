
module "ecs-cluster-for-dbt" {
  source          = "./modules/ecs-cluster"
  PROJECT_NAME    = local.PROJECT_NAME
  ENV             = local.ENV
  RESOURCE_SUFFIX = "cluster-for-dbt"
  AWS_TAGS        = var.AWS_TAGS
}

module "ecs-task-definition" {
  source              = "./modules/ecs-task-definition"
  ENV                 = local.ENV
  PROJECT_NAME        = local.PROJECT_NAME
  AWS_TAGS            = local.AWS_TAGS
  RESOURCE_SUFFIX     = "task-definition-for-dbt"
  ECR_REPOSITORY_URL  = module.ecr-repository.repository_url
  ECR_IMAGE_NAME      = "data-engineering-challenge-latest"
  DBT_ECS_CLUSTER_ARN = module.ecs-cluster-for-dbt.arn
}

module "ecr-repository" {
  source          = "./modules/ecr"
  ENV             = local.ENV
  PROJECT_NAME    = local.PROJECT_NAME
  AWS_TAGS        = local.AWS_TAGS
  RESOURCE_SUFFIX = "images-repository"
}