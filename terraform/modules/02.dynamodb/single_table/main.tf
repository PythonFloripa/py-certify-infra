# Single Table Design - DynamoDB
# Baseado no padrão: https://aws.amazon.com/pt/blogs/compute/creating-a-single-table-design-with-amazon-dynamodb/
#
# Entity Patterns:
#   PK: EntityType#EntityId (ex: ORDER#123, PRODUCT#1, PARTICIPANT#uuid, CERTIFICATE#123)
#   SK: EntityType#EntityId (mesmo formato para acesso direto)
#
# GSIs para padrões de acesso:
#   GSI1: Acesso por UUID (certificate by ID)
#   GSI2: Acesso por email (orders, certificates, participants)
#   GSI3: Acesso por product (products, orders, certificates)
#   GSI4: Acesso por success flag (certificates)

resource "aws_dynamodb_table" "single_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # Atributos base - entidades
  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  attribute {
    name = "GSI2PK"
    type = "S"
  }

  attribute {
    name = "GSI2SK"
    type = "S"
  }

  attribute {
    name = "GSI3PK"
    type = "S"
  }

  attribute {
    name = "GSI3SK"
    type = "S"
  }

  attribute {
    name = "GSI4PK"
    type = "S"
  }

  attribute {
    name = "GSI4SK"
    type = "S"
  }

  # EntityType para identificação rápida do tipo
  attribute {
    name = "EntityType"
    type = "S"
  }

  # GSI1: CERT# lookups (certificate find_by_id)
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
  }

  # GSI2: EMAIL# lookups (email lookups across entities)
  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2PK"
    range_key       = "GSI2SK"
    projection_type = "ALL"
  }

  # GSI3: PRODUCT# lookups (product lookups)
  global_secondary_index {
    name            = "GSI3"
    hash_key        = "GSI3PK"
    range_key       = "GSI3SK"
    projection_type = "ALL"
  }

  # GSI4: SUCCESS# lookups (certificate success flag)
  global_secondary_index {
    name            = "GSI4"
    hash_key        = "GSI4PK"
    range_key       = "GSI4SK"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = var.table_name
    Environment = var.environment
    Project     = var.project_name
    Design      = "SingleTable"
    CostCenter  = "low-cost"
  }
}
