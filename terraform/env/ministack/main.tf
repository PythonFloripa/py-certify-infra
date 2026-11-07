# S3 Bucket
module "s3" {
  source       = "../../modules/03.bucket_s3"
  bucket_name  = "${var.project_name}-${var.environment}-bucket"
  environment  = var.environment
  project_name = var.project_name
  region       = var.aws_region
}

# DynamoDB Single Table
module "dynamodb_single_table" {
  source       = "../../modules/02.dynamodb/single_table"
  table_name   = "${var.project_name}-${var.environment}"
  environment  = var.environment
  project_name = var.project_name
}

# SQS
module "sqs" {
  source       = "../../modules/04.sqs"
  project_name = var.project_name
  environment  = var.environment
}

# Lambda
module "lambda" {
  source                                  = "../../modules/05.lambda"
  project_name                            = var.project_name
  environment                             = var.environment
  aws_region                              = var.aws_region
  lambda_timeout                          = var.lambda_timeout
  lambda_memory_size                      = var.lambda_memory_size
  log_retention_days                      = var.log_retention_days
  url_service_tech                        = var.url_service_tech
  prefix_api_version                      = var.prefix_api_version
  service_url_registration_api_solana     = var.service_url_registration_api_solana
  service_api_key_registration_api_solana = var.service_api_key_registration_api_solana
  tech_floripa_certificate_validate_url   = var.tech_floripa_certificate_validate_url
  tech_floripa_logo_url                   = var.tech_floripa_logo_url
  builder_queue_url                       = module.sqs.builder_queue_url
  builder_queue_arn                       = module.sqs.builder_queue_arn
  notification_queue_arn                  = module.sqs.notification_queue_arn
  notification_queue_url                  = module.sqs.notification_queue_url
  dynamodb_table_arns = [
    module.dynamodb_single_table.table_arn
  ]
  s3_bucket_arn            = module.s3.bucket_arn
  s3_bucket_name           = module.s3.bucket_name
  api_gateway_download_url = module.api_gateway.api_endpoint_download_certificate
}

# API Gateway
module "api_gateway" {
  source               = "../../modules/06.api-gateway"
  project_name         = var.project_name
  environment          = var.environment
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit
  api_key_value        = var.api_key_value
}
