output "table_name" {
  value       = aws_dynamodb_table.single_table.name
  description = "Nome da tabela única"
}

output "table_arn" {
  value       = aws_dynamodb_table.single_table.arn
  description = "ARN da tabela única"
}

output "table_id" {
  value       = aws_dynamodb_table.single_table.id
  description = "ID da tabela única"
}
