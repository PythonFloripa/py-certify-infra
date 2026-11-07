# Informações do s3
output "s3_bucket_name" {
  description = "Nome do bucket S3"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN do bucket S3"
  value       = module.s3.bucket_arn
}

# Informações da tabela única DynamoDB (single-table design)
output "dynamodb_single_table_name" {
  description = "Nome da tabela DynamoDB única"
  value       = module.dynamodb_single_table.table_name
}

output "dynamodb_single_table_arn" {
  description = "ARN da tabela DynamoDB única"
  value       = module.dynamodb_single_table.table_arn
}

# Informações do SQS
output "sqs_queue_url" {
  description = "URL da fila SQS principal"
  value       = module.sqs.queue_url
}

output "sqs_queue_arn" {
  description = "ARN da fila SQS principal"
  value       = module.sqs.queue_arn
}

output "sqs_dlq_url" {
  description = "URL da Dead Letter Queue (builder)"
  value       = module.sqs.builder_dlq_url
}

# Informações do Lambda
output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN da função Lambda"
  value       = module.lambda.function_arn
}

output "lambda_builder_function_name" {
  description = "Nome da função Lambda Builder"
  value       = module.lambda.builder_function_name
}

output "lambda_builder_function_arn" {
  description = "ARN da função Lambda Builder"
  value       = module.lambda.builder_function_arn
}

# Informações da Lambda de Notificação
output "lambda_notification_function_name" {
  description = "Nome da função Lambda de Notificação"
  value       = module.lambda.notification_function_name
}

output "lambda_notification_function_arn" {
  description = "ARN da função Lambda de Notificação"
  value       = module.lambda.notification_function_arn
}

# Informações do API Gateway
output "api_gateway_url" {
  description = "URL base do API Gateway"
  value       = module.api_gateway.api_url
}

output "api_gateway_endpoint_create_certificate" {
  description = "URL completa do endpoint para criar certificado"
  value       = module.api_gateway.api_endpoint_create_certificate
}

output "api_gateway_endpoint_download_certificate" {
  description = "URL base do endpoint para download de certificados"
  value       = module.api_gateway.api_endpoint_download_certificate
}

output "api_gateway_id" {
  description = "ID do API Gateway"
  value       = module.api_gateway.api_id
}

# Resumo completo da infraestrutura
output "infrastructure_summary" {
  description = "Resumo completo da infraestrutura criada"
  value = {
    api_gateway = {
      id                   = module.api_gateway.api_id
      url                  = module.api_gateway.api_url
      endpoint_create_cert = module.api_gateway.api_endpoint_create_certificate
    }
    lambda = {
      function_name              = module.lambda.function_name
      function_arn               = module.lambda.function_arn
      builder_function_name      = module.lambda.builder_function_name
      builder_function_arn       = module.lambda.builder_function_arn
      notification_function_name = module.lambda.notification_function_name
      notification_function_arn  = module.lambda.notification_function_arn
    }
    sqs = {
      queue_url = module.sqs.queue_url
      dlq_url   = module.sqs.builder_dlq_url
    }
    environment = var.environment
    project     = var.project_name
  }
}
