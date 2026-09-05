# Certified Builder Infra PY

## Visão Geral do Projeto

Este projeto contém a infraestrutura como código (IaC) para a aplicação "Certified Builder". A infraestrutura é gerenciada com Terraform e provisiona os recursos necessários na AWS para executar a aplicação de forma escalável e econômica.

## Tecnologias Utilizadas

- **Terraform**: Ferramenta de infraestrutura como código para provisionar e gerenciar os recursos na nuvem.
- **AWS (Amazon Web Services)**: Provedor de nuvem onde a infraestrutura da aplicação é hospedada.

## Estrutura de Pastas

A estrutura de pastas do projeto é organizada da seguinte forma:

```
/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   ├── api-gateway/
│   ├── bucket_s3/
│   ├── dynamodb/
│   │   └── single_table/        # Single-table design
│   ├── lambda/
│   └── sqs/
└── README.md
```

- **terraform/**: Contém todos os arquivos de configuração do Terraform.
- **terraform/main.tf**: Arquivo principal que define os módulos e a configuração do provider.
- **terraform/variables.tf**: Declaração das variáveis utilizadas no projeto.
- **terraform/outputs.tf**: Definição dos outputs do Terraform.
- **terraform/terraform.tfvars.example**: Arquivo de exemplo para as variáveis do Terraform.
- **terraform/[module]/**: Cada pasta representa um módulo do Terraform que provisiona um serviço específico na AWS.

## Serviços Criados e Suas Variáveis

A seguir estão os serviços da AWS criados por este projeto e suas respectivas variáveis de configuração.

### API Gateway

- **Descrição**: Cria um API Gateway REST para expor a aplicação Lambda como uma API.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy (dev, staging, prod).
    - `lambda_function_name`: Nome da função Lambda.
    - `lambda_invoke_arn`: ARN para invocar a função Lambda.
    - `throttle_rate_limit`: Limite de taxa por segundo para throttling.
    - `throttle_burst_limit`: Limite de burst para throttling.
    - `api_key_value`: Valor da API Key para autenticação.

### S3 Bucket

- **Descrição**: Cria um bucket S3 para armazenar os arquivos do projeto.
- **Variáveis**:
    - `bucket_name`: Nome do bucket S3.
    - `environment`: Ambiente de deploy.
    - `project_name`: Nome do projeto.
    - `region`: Região da AWS.
    - `lifecycle_rule`: Regras de ciclo de vida dos objetos S3.

### DynamoDB Single-Table

- **Descrição**: Cria a tabela DynamoDB com padrão Single-Table Design.
- **Módulo**: `single_table`
- **Variáveis**:
    - `table_name`: Nome da tabela.
    - `environment`: Ambiente de deploy.
    - `project_name`: Nome do projeto.

#### Estrutura da Tabela

A tabela utiliza um design Single-Table com chaves compostas e 5 Global Secondary Indexes (GSIs).

| Atributo | Tipo | Descrição |
|----------|------|-----------|
| `PK` | String | Chave de Partição principal |
| `SK` | String | Chave de Ordenação principal |
| `GSI1PK`, `GSI1SK` | String | GSI1 - Certificate por UUID |
| `GSI2PK`, `GSI2SK` | String | GSI2 - Orders, Certificates, Participants por email |
| `GSI3PK`, `GSI3SK` | String | GSI3 - Products por nome, Certificates/Orders por product |
| `GSI4PK`, `GSI4SK` | String | GSI4 - Certificados por status de sucesso |
| `GSI5PK`, `GSI5SK` | String | GSI5 - Participants por cidade |

#### GSIs (Global Secondary Indexes)

| GSI | Key Schema | Access Pattern |
|-----|------------|----------------|
| GSI1 | `PK: UUID, SK: CERT#` | Certificate by UUID |
| GSI2 | `PK: email, SK: ENTITY#` | Orders, Certificates, Participants by email |
| GSI3 | `PK: product, SK: ENTITY#` | Products by name, Certificates/Orders by product |
| GSI4 | `PK: SUCCESS#Y/N, SK: CERT#` | Successful/Failed certificates |
| GSI5 | `PK: CITY#name, SK: PART#` | Participants by city |

#### Entidades Suportadas

| Entidade | PK | SK | GSIs Utilizados |
|----------|----|----|----------------|
| Certificate | `CERTIFICATE#<uuid>` | `CERTIFICATE#<uuid>` | GSI1, GSI2, GSI3, GSI4 |
| Order | `ORDER#<order_id>` | `ORDER#<order_id>` | GSI2, GSI3 |
| Product | `PRODUCT#<product_id>` | `PRODUCT#<product_id>` | GSI3 |
| Participant | `PARTICIPANT#<uuid>` | `PARTICIPANT#<uuid>` | GSI2, GSI5 |

### Lambda

- **Descrição**: Cria as funções Lambda no formato ZIP e a infraestrutura associada.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy.
    - `aws_region`: Região AWS.
    - `lambda_timeout`: Timeout da função Lambda em segundos.
    - `lambda_memory_size`: Memória alocada para a função Lambda em MB.
    - `log_retention_days`: Dias de retenção dos logs do CloudWatch.
    - `builder_queue_url`: URL da fila SQS builder.
    - `url_service_tech`: URL do serviço Tech Floripa.
    - `prefix_api_version`: Prefixo da versão da API.
    - `dynamodb_table_arns`: ARNs das tabelas DynamoDB.
    - `builder_queue_arn`: ARN da fila SQS builder.
    - `notification_queue_arn`: ARN da fila SQS notification.
    - `notification_queue_url`: URL da fila SQS notification.
    - `s3_bucket_arn`: ARN do bucket S3.
    - `s3_bucket_name`: Nome do bucket S3.
    - `api_gateway_download_url`: URL base do endpoint de download do API Gateway.

## Fluxo de Deploy

- O Terraform cria as funções Lambda, roles, filas SQS, tabelas DynamoDB, bucket S3 e API Gateway.
- Cada função é inicializada com um ZIP placeholder mínimo apenas para permitir a criação do recurso.
- Os repositórios `certified-builder-api-py`, `certified_builder_py` e `certified-builder-notification-py` publicam o código real usando `aws lambda update-function-code`.
- O fluxo local com Docker é apenas para emulação de runtime em `localhost:9000`.

### SQS (Simple Queue Service)

- **Descrição**: Cria as filas SQS para processamento assíncrono.
- **Variáveis**:
    - `project_name`: Nome do projeto.
    - `environment`: Ambiente de deploy.
    - `queue_name_builder`: Nome da fila de build.
    - `queue_name_builder_dlq`: Nome da fila de build DLQ.
    - `queue_name_notification`: Nome da fila de notificação.
    - `queue_name_notification_dlq`: Nome da fila de notificação DLQ.

## Projetos Relacionados

- **[certified-builder-py](https://github.com/PythonFloripa/certified_builder_py)**: Este projeto gera certificados personalizados para participantes de eventos, processando mensagens do SQS e utilizando templates predefinidos.
- **[certified-builder-notification-py](https://github.com/PythonFloripa/certified-builder-notification-py)**: Este projeto é uma função AWS Lambda responsável por processar notificações de certificados gerados. Ele é acionado por mensagens em uma fila SQS, atualiza o status dos certificados e notifica um serviço externo sobre a conclusão.
- **[certified-builder-api-py](https://github.com/PythonFloripa/certified-builder-api-py)**: Esta API é responsável por gerenciar a criação, consulta e download de certificados. Ela é construída como uma função Lambda da AWS, utilizando uma arquitetura serverless.
