# Variáveis para o módulo Lambda

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "lambda_timeout" {
  description = "Timeout da função Lambda em segundos"
  type        = number
  default     = 900
}

variable "lambda_memory_size" {
  description = "Memória alocada para a função Lambda em MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs do CloudWatch"
  type        = number
  default     = 90
}


variable "builder_queue_url" {
  description = "URL da fila SQS builder"
  type        = string
}

variable "url_service_tech" {
  description = "URL do serviço Tech Floripa"
  type        = string
}

variable "prefix_api_version" {
  description = "Prefixo da versão da API"
  type        = string
  default     = "/api/v1"
}

# ARNs das tabelas DynamoDB para políticas IAM
variable "dynamodb_table_arns" {
  description = "ARNs das tabelas DynamoDB"
  type        = list(string)
}


variable "builder_queue_arn" {
  description = "ARN da fila SQS builder"
  type        = string
}

variable "notification_queue_arn" {
  description = "ARN da fila SQS notification"
  type        = string
}

variable "notification_queue_url" {
  description = "URL da fila SQS notification"
  type        = string
}

# ARN do bucket S3 para políticas IAM
variable "s3_bucket_arn" {
  description = "ARN do bucket S3"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nome do bucket S3"
  type        = string
}

variable "api_gateway_download_url" {
  description = "URL base do endpoint de download do API Gateway"
  type        = string
}

variable "service_url_registration_api_solana" {
  description = "URL do serviço de registro da API Solana"
  type        = string
}

variable "service_api_key_registration_api_solana" {
  description = "API Key do serviço de registro da API Solana"
  type        = string
  sensitive   = true
}

variable "tech_floripa_certificate_validate_url" {
  description = "URL para validação de certificados do Tech Floripa"
  type        = string
}

variable "tech_floripa_logo_url" {
  description = "URL do logo do Tech Floripa"
  type        = string
}
